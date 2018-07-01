@TestOn("vm")
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:io' hide File, Directory;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:dev_test/test.dart';
import 'package:tekartik_fs_test/test_common.dart';
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
  return join(pkg.path, 'bin', 'fsdeploy.dart');
}

FileSystemTestContext ctx = new FileSystemTestContextIo();
FileSystem fs = ctx.fs;
main() {
  //defineTests(ctx);
  //useVMConfiguration();
  group('fsdeploy', () {
    test('version', () async {
      ProcessResult result =
          await runCmd(dartCmd([dirdeployDartScript, '--version']));
      List<String> parts =
          LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'fsdeploy');
      expect(new Version.parse(parts.last), version);
    });

    test('deploy.yaml', () async {
      var top = await ctx.prepare();
      //Directory
      Directory dir = fs.directory(join(top.path, 'dir'));
      File file = fs.file(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);
      File deployYamlFile = fs.file(join(dir.path, "deploy.yaml"));
      await deployYamlFile.create();

      Directory dst = fs.directory(join(top.path, 'dst'));

      await runCmd(
          dartCmd([dirdeployDartScript, deployYamlFile.path, dst.path]));
      //await runCmd(dartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
    });

    test('deploy.yaml_exclude', () async {
      var top = await ctx.prepare() as Directory;
      //Directory
      Directory dir = fs.directory(join(top.path, 'dir'));
      File file = fs.file(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);
      File file2 = fs.file(join(dir.path, "file2"));
      await file2.create(recursive: true);
      await file2.writeAsString("test", flush: true);

      File deployYamlFile = fs.file(join(dir.path, "deploy.yaml"));
      await deployYamlFile.create();
      await deployYamlFile.writeAsString('''
      exclude:
        - file
      ''');

      Directory dst = fs.directory(join(top.path, 'dst'));

      await runCmd(dartCmd(
          [dirdeployDartScript, deployYamlFile.path, dir.path, dst.path]));
      //await runCmd(dartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
      expect(await fs.newFile(join(dst.path, "file2")).readAsString(), "test");
      expect(await fs.newFile(join(dst.path, "file")).exists(), isFalse);
    });

    test('dir', () async {
      var top = await ctx.prepare() as Directory;
      //Directory
      Directory dir = fs.directory(join(top.path, 'dir'));
      File file = fs.file(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);

      Directory dst = fs.directory(join(top.path, 'dst'));

      await runCmd(dartCmd([dirdeployDartScript, "--dir", dir.path, dst.path]));
      //await runCmd(dartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));

      String filePath = join(dst.path, 'file');

      expect(await fs.file(filePath).readAsString(), "test");

      if (fs.supportsFileLink) {
        expect(await fs.type(filePath), FileSystemEntityType.link);
      }
    });
  });
}
