@TestOn("vm")
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:convert';
import 'dart:io' hide File, Directory, FileSystemEntityType;

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_pub/io.dart';

import 'fs_test_common_io.dart';
import 'io_test_common.dart';

String get _pubPackageRoot => '.';

String get dirdeployDartScript {
  PubPackage pkg = PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'fsdeploy.dart');
}

FileSystemTestContext ctx = FileSystemTestContextIo();
FileSystem fs = ctx.fs;

void main() {
  //defineTests(ctx);
  //useVMConfiguration();
  group('fsdeploy', () {
    test('version', () async {
      ProcessResult result =
          await runCmd(DartCmd([dirdeployDartScript, '--version']));
      List<String> parts =
          LineSplitter.split(result.stdout as String).first.split(' ');
      expect(parts.first, 'fsdeploy');
      expect(Version.parse(parts.last), version);
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
          DartCmd([dirdeployDartScript, deployYamlFile.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
    });

    test('deploy.yaml_exclude', () async {
      var top = await ctx.prepare();
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

      await runCmd(DartCmd(
          [dirdeployDartScript, deployYamlFile.path, dir.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
      expect(await fs.file(join(dst.path, "file2")).readAsString(), "test");
      expect(await fs.file(join(dst.path, "file")).exists(), isFalse);
    });

    test('dir', () async {
      var top = await ctx.prepare();
      //Directory
      Directory dir = fs.directory(join(top.path, 'dir'));
      File file = fs.file(join(dir.path, "file"));
      await file.create(recursive: true);
      await file.writeAsString("test", flush: true);

      Directory dst = fs.directory(join(top.path, 'dst'));

      await runCmd(DartCmd([dirdeployDartScript, "--dir", dir.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));

      String filePath = join(dst.path, 'file');

      expect(await fs.file(filePath).readAsString(), "test");

      if (fs.supportsFileLink) {
        expect(await fs.type(filePath, followLinks: false),
            FileSystemEntityType.link);
      }
    });
  });
}
