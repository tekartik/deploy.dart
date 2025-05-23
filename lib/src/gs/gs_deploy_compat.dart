library;

//import 'dart:io';

import 'package:fs_shim/utils/io/copy.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:tekartik_deploy/src/gsutil.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';

final argOut = 'out';

@Deprecated('use gsUtilCmd')
ProcessCmd gsutilCmd(List<String> args) => gsUtilCmd(args);

ProcessCmd gsUtilCmd(List<String> args) => GsUtilCmd(gsUtilExecutable!, args);

/// synchronize from src to dst (no delete)
ProcessCmd gsutilRsyncCmd(
  String src,
  String dst, {
  bool? recursive,
  bool? parallel,
  // Causes the rsync command to compute and compare checksums (instead of comparing mtime) for files
  // if the size of source and destination as well as mtime (if available) match.
  // This option increases local disk I/O and run time if either src_url or dst_url are on the local file system.
  bool? useChecksum,
  Map<String, String?>? header,
}) {
  final args = <String>[];

  // run operation in parallel, good when src or dest is is a bucket
  if (parallel == true) {
    args.add('-m');
  }
  if (header != null) {
    header.forEach((String key, String? value) {
      if (value == null) {
        args.addAll(['-h', key]);
      } else {
        args.addAll(['-h', '$key:$value']);
      }
    });
  }
  args.add('rsync');
  if (useChecksum == true) {
    args.add('-c');
  }
  if (recursive == true) {
    args.add('-r');
  }
  args.addAll([src, dst]);
  return gsUtilCmd(args);
}

ProcessCmd gsutilCopyCmd(String src, String dst, {bool? recursive}) {
  final gsutilArgs = <String>[];

  // Assume a log of files
  if (recursive == true) {
    gsutilArgs.add('-m');
  }

  gsutilArgs.add('cp');

  if (recursive == true) {
    gsutilArgs.add('-R');

    src = join(src, '*');
  }

  gsutilArgs.addAll([
    '-v',
    '-z',
    'html,css,js,json',
    '-a',
    'public-read',
    src,
    dst,
  ]);

  return gsUtilCmd(gsutilArgs);
}

const encodingGZipFolder = 'gzip';
const encodingNoneFolder = 'none';

// gsutil setwebcfg -m index.html gs://gstest.tekartik.com
//ProcessCmd gsDeployCmd(String src, String dst) => gsutilRsyncCmd(src, dst);
ProcessCmd gsDeployCmd(
  String src,
  String dst, {
  bool recursive = true,
  bool parallel = true,
}) => gsutilRsyncCmd(src, dst, recursive: recursive, parallel: parallel);

List<ProcessCmd> gsWebDeployCmds(String src, String dst) {
  final gzipCmd = gsutilRsyncCmd(
    join(src, encodingGZipFolder),
    join(dst),
    recursive: true,
    parallel: true,
    useChecksum: true,
    header: {'Content-Encoding': 'gzip'},
  );
  final noneCmd = gsutilRsyncCmd(
    join(src, encodingNoneFolder),
    join(dst),
    recursive: true,
    parallel: true,
    useChecksum: true,
  );
  return [gzipCmd, noneCmd];
}

// Create a gzip and none folder in a gs folder
Future gsWebPrepareForRsync(String src, String dst) async {
  final gzipFilter = <String>[
    '*.html',
    '*.js',
    '*.json',
    '*.appcache',
    '*.css',
    '*.txt',
  ];
  await copyDirectory(
    Directory(src),
    Directory(join(dst, encodingGZipFolder)),
    options: recursiveLinkOrCopyNewerOptions..include = gzipFilter,
  );
  await copyDirectory(
    Directory(src),
    Directory(join(dst, encodingNoneFolder)),
    options: recursiveLinkOrCopyNewerOptions..exclude = gzipFilter,
  );
}

// gzip in place
Future _gzip(String src) async {
  final futures = <Future>[];
  futures.add(
    Directory(src).list(recursive: true).listen((FileSystemEntity fse) {
      futures.add(() async {
        // ignore: avoid_slow_async_io
        if (await FileSystemEntity.isFile(fse.path)) {
          //print(fse.path);
          final file = File(fse.path);
          final data = gzip.encode(await file.readAsBytes());
          await file.delete();
          await file.writeAsBytes(data);
        }
      }());
    }).asFuture(),
  );
  await Future.wait(futures);
}

Future gsWebDeploy(String src, String gsDst) async {
  final name = basename(src);
  final srcParent = dirname(src);
  final gsSrc = join(srcParent, 'gs', name);
  await gsWebPrepareForRsync(src, gsSrc);

  final gzipFolder = join(gsSrc, encodingGZipFolder);
  stdout.writeln('Zipping $gzipFolder');
  await _gzip(gzipFolder);

  for (final cmd in gsWebDeployCmds(gsSrc, gsDst)) {
    await runCmd(cmd, verbose: true);
  }
}
