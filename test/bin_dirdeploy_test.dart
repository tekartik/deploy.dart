@TestOn("vm")
library tekartik_deploy.test.bin_dirdeploy_test;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_pub/pub.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'dart:io';
import 'io_test_common.dart';
import 'dart:convert';

String get _pubPackageRoot => getPubPackageRootSync(testDirPath);

String get scpullDartScript {
  PubPackage pkg = new PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'dirdeploy.dart');
}

void main() {
  //useVMConfiguration();
  group('scclone', () {
    test('version', () async {
      ProcessResult result =
          await runCmd(dartCmd([scpullDartScript, '--version']));
      List<String> parts = LineSplitter.split(result.stdout).first.split(' ');
      expect(parts.first, 'dirdeploy');
      expect(new Version.parse(parts.last), version);
    });
  });
}
