library tekartik_deploy.gs_deploy;

//import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';

import 'src/gsutil.dart';

final ARG_OUT = 'out';


// User [gsUtilCmd]
@deprecated
ProcessCmd gsutilCmd(List<String> args) => gsUtilCmd(args);

ProcessCmd gsUtilCmd(List<String> args) =>
    new GsUtilCmd(gsUtilExecutable, args);

/// synchronize from src to dst (no delete)
ProcessCmd gsutilRsyncCmd(String src, String dst, {bool recursive, bool parallel}) {
  List<String> args = [];

  // run operation in parallel, good when src or dest is is a bucket
  if (parallel == true) {
    args.add('-m');
  }
  args.add('rsync');
  if (recursive == true) {
    args.add('-r');
  }
  args.addAll([src, dst]);
  return gsUtilCmd(args);
}

ProcessCmd gsutilCopyCmd(String src, String dst, {bool recursive}) {
  List<String> gsutilArgs = [];

  // Assume a log of files
  if (recursive == true) {
    gsutilArgs.add('-m');
  }

  gsutilArgs.add('cp');

  if (recursive == true) {
    gsutilArgs.add('-R');

    src = join(src, '*');
  }

  gsutilArgs
      .addAll(['-v', '-z', 'html,css,js,json', '-a', 'public-read', src, dst]);

  return gsUtilCmd(gsutilArgs);
}

// gsutil setwebcfg -m index.html gs://gstest.tekartik.com
//ProcessCmd gsDeployCmd(String src, String dst) => gsutilRsyncCmd(src, dst);
ProcessCmd gsDeployCmd(String src, String dst, {bool recursive: true, bool parallel: true}) =>
    gsutilRsyncCmd(src, dst, recursive: recursive, parallel: parallel);
