@TestOn('vm')
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'package:tekartik_pub/io.dart';

import 'fs_test_common_io.dart';
import 'io_test_common.dart';

String get _pubPackageRoot => '.';

String get gswebdeployDartScript {
  final pkg = PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'gswebdeploy.dart');
}

void main() {
  //defineTests(ctx);
  //useVMConfiguration();
  group('gsdeploy', () {
    test('version', () async {
      final result =
          await runCmd(DartCmd([gswebdeployDartScript, '--version']));
      final parts =
          LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'gswebdeploy');
      expect(Version.parse(parts.last), version);
    });
    test('check', () async {
      var result = await runCmd(DartCmd([gswebdeployDartScript, '--check']),
          verbose: true);
      assert(result.exitCode == 0 || result.exitCode == 1);
      /*
      List<String> parts =
      LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'gsdeploy');
      expect(Version.parse(parts.last), version);
      */
    });

    /*
    test('deploy_1_file', () async {
      Directory top = await ctx.prepare();
      //Directory
      Directory dir = new Directory(join(top.path, 'dir'));
      File file = new File(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);
      File deployYamlFile = new File(join(dir.path, 'deploy.yaml'));
      await deployYamlFile.create();

      Directory dst = new Directory(join(top.path, 'dst'));

      await runCmd(
          DartCmd([dirdeployDartScript, deployYamlFile.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
    });

    test('dir', () async {
      Directory top = await ctx.prepare();
      //Directory
      Directory dir = new Directory(join(top.path, 'dir'));
      File file = new File(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);

      Directory dst = new Directory(join(top.path, 'dst'));

      await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));

      String filePath = join(dst.path, 'file');

      expect(await new File(filePath).readAsString(), 'test');

      if (fs.supportsFileLink) {
        expect(await FileSystemEntity.isLink(filePath), isTrue);
      }
    });
    */
  });
}
