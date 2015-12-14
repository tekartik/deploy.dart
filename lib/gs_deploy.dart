library tekartik_deploy.gs_deploy;

//import 'dart:io';

import 'package:process_run/cmd_run.dart';

final ARG_OUT = 'out';

ProcessCmd gsutilCmd(List<String> args) => processCmd('gsutil', args);

/// synchronize from src to dst (no delete)
ProcessCmd gsutilRsyncCmd(String src, String dst) {
  List<String> args = ['rsync', '-r', src, dst];
  return gsutilCmd(args);
}

// gsutil setwebcfg -m index.html gs://gstest.tekartik.com
ProcessCmd gsDeployCmd(String src, String dst) => gsutilRsyncCmd(src, dst);
