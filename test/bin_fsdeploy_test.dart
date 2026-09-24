@TestOn('vm')
library;

import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_pub/io.dart';

import 'fs_test_common_io.dart';

String get _pubPackageRoot => '.';

String get dirdeployDartScript {
  final pkg = PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'fsdeploy.dart');
}

void main() {
  var ctx = FileSystemTestContextIo('bin_fs_deploy');
  var fs = ctx.fs;

  //defineTests(ctx);
  //useVMConfiguration();
  group('fsdeploy', () {
    test('version', () async {
      final result = await runCmd(DartCmd([dirdeployDartScript, '--version']));
      final parts = LineSplitter.split(
        result.stdout as String,
      ).first.split(' ');
      expect(parts.first, 'fsdeploy');
      expect(Version.parse(parts.last), version);
    });

    test('deploy.yaml', () async {
      var top = await ctx.prepare();
      //Directory
      final dir = fs.directory(join(top.path, 'dir'));
      final file = fs.file(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);
      final deployYamlFile = fs.file(join(dir.path, 'deploy.yaml'));
      await deployYamlFile.create();

      final dst = fs.directory(join(top.path, 'dst'));

      await runCmd(
        DartCmd([dirdeployDartScript, deployYamlFile.path, dst.path]),
      );
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
    });

    test('deploy.yaml_exclude', () async {
      var top = await ctx.prepare();
      //Directory
      final dir = fs.directory(join(top.path, 'dir'));
      final file = fs.file(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);
      final file2 = fs.file(join(dir.path, 'file2'));
      await file2.create(recursive: true);
      await file2.writeAsString('test', flush: true);

      final deployYamlFile = fs.file(join(dir.path, 'deploy.yaml'));
      await deployYamlFile.create();
      await deployYamlFile.writeAsString('''
      exclude:
        - file
      ''');

      final dst = fs.directory(join(top.path, 'dst'));

      await runCmd(
        DartCmd([dirdeployDartScript, deployYamlFile.path, dir.path, dst.path]),
      );
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));
      expect(await fs.file(join(dst.path, 'file2')).readAsString(), 'test');
      expect(await fs.file(join(dst.path, 'file')).exists(), isFalse);
    });

    test('deploy.yaml_optional', () async {
      var top = await ctx.prepare();
      final dir = fs.directory(join(top.path, 'dir'));
      for (var path in ['index.html', 'main.dart.js', 'flutter.js', 'a/b']) {
        final file = fs.file(join(dir.path, path));
        await file.create(recursive: true);
        await file.writeAsString(path, flush: true);
      }
      final deployYamlFile = fs.file(join(dir.path, 'deploy.yaml'));
      await deployYamlFile.writeAsString('''
      files:
        - index.html
        - main.dart.{js,wasm}
        - a/
      optional:
        - flutter*.js
        - favicon.png
      ''');

      Future<void> check(Directory dst) async {
        for (var path in ['index.html', 'main.dart.js', 'flutter.js', 'a/b']) {
          expect(await fs.file(join(dst.path, path)).readAsString(), path);
        }
        for (var path in ['main.dart.wasm', 'favicon.png', 'deploy.yaml']) {
          expect(await fs.file(join(dst.path, path)).exists(), isFalse);
        }
      }

      // yaml file
      var dst = fs.directory(join(top.path, 'dst'));
      await runCmd(
        DartCmd([dirdeployDartScript, deployYamlFile.path, dir.path, dst.path]),
      );
      await check(dst);

      // scan for deploy.yaml
      dst = fs.directory(join(top.path, 'dst_scan'));
      await runCmd(DartCmd([dirdeployDartScript, dir.path, dst.path]));
      await check(dst);
    });

    test('dir', () async {
      var top = await ctx.prepare();
      //Directory
      final dir = fs.directory(join(top.path, 'dir'));
      final file = fs.file(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);

      final dst = fs.directory(join(top.path, 'dst'));

      await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //await runCmd(DartCmd([dirdeployDartScript, '--dir', dir.path, dst.path]));
      //print(processResultToDebugString(result));

      final filePath = join(dst.path, 'file');

      expect(await fs.file(filePath).readAsString(), 'test');

      // 2020-01-20 used to be link
      //if (fs.supportsFileLink) {
      expect(
        await fs.type(filePath, followLinks: false),
        FileSystemEntityType.file,
      );
      //}
    });
  });
}
