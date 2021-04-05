@TestOn('vm')
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:core';

import 'package:test/test.dart';
import 'package:process_run/cmd_run.dart';
import 'package:tekartik_deploy/gs_deploy.dart';
import 'package:tekartik_deploy/src/gsutil.dart';

//import 'package:fs_shim_test/test_io.dart';
//import 'io_test_common.dart';

//String get _pubPackageRoot => getPubPackageRootSync(testDirPath);

void main() {
  //defineTests(ctx);
  //useVMConfiguration();
  var gsUtilAvailable = false;
  try {
    findGsUtilSync();
    gsUtilAvailable = true;
  } catch (_) {}
  group('gsutil', () {
    test('version', () async {
      final result = await runCmd(gsUtilCmd(['--version']));
      expect(result.stdout, contains('gsutil version'));
    });
  }, skip: !gsUtilAvailable);
}
