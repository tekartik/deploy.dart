library tekartik_deploy.gs_deploy;

//import 'dart:io';

import 'package:process_run/cmd_run.dart';
import 'package:path/path.dart';

final ARG_OUT = 'out';

ProcessCmd gsutilCmd(List<String> args) => processCmd('gsutil', args);

/// synchronize from src to dst (no delete)
ProcessCmd gsutilRsyncCmd(String src, String dst) {
  List<String> args = ['rsync', '-r', src, dst];
  return gsutilCmd(args);
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

  return gsutilCmd(gsutilArgs);
}

// gsutil setwebcfg -m index.html gs://gstest.tekartik.com
//ProcessCmd gsDeployCmd(String src, String dst) => gsutilRsyncCmd(src, dst);
ProcessCmd gsDeployCmd(String src, String dst) =>
    gsutilCopyCmd(src, dst, recursive: true);
