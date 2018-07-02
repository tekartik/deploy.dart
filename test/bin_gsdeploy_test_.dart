@TestOn("vm")
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:io';

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_pub/io.dart';
//import 'package:tekartik_pub/script.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'fs_test_common_io.dart';
import 'io_test_common.dart';
import 'dart:convert';

String get _pubPackageRoot => '.';

String get dirdeployDartScript {
  PubPackage pkg = new PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'gsdeploy.dart');
}

main() {
  //defineTests(ctx);
  //useVMConfiguration();
  group('gsdeploy', () {
    test('version', () async {
      ProcessResult result =
          await runCmd(dartCmd([dirdeployDartScript, '--version']));
      List<String> parts =
          LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'gsdeploy');
      expect(new Version.parse(parts.last), version);
    });

    /*
    test('deploy_1_file', () async {
      Directory top = await ctx.prepare();
      //Directory
      Directory dir = new Directory(join(top.path, 'dir'));
      File file = new File(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);
      File deployYamlFile = new File(join(dir.path, "deploy.yaml"));
      await deployYamlFile.create();

      Directory dst = new Directory(join(top.path, 'dst'));

      await runCmd(
          dartCmd([dirdeployDartScript, deployYamlFile.path, dst.path]));
      //await runCmd(dartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
    });

    test('dir', () async {
      Directory top = await ctx.prepare();
      //Directory
      Directory dir = new Directory(join(top.path, 'dir'));
      File file = new File(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);

      Directory dst = new Directory(join(top.path, 'dst'));

      await runCmd(dartCmd([dirdeployDartScript, "--dir", dir.path, dst.path]));
      //await runCmd(dartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));

      String filePath = join(dst.path, 'file');

      expect(await new File(filePath).readAsString(), "test");

      if (fs.supportsFileLink) {
        expect(await FileSystemEntity.isLink(filePath), isTrue);
      }
    });
    */
  });
}
