@TestOn('vm')
library tekartik_deploy.test.bin_dirdeploy_test;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:tekartik_pub/io.dart';

import 'fs_test_common_io.dart'
    show FileSystemTestContext, fileSystemTestContextIo, FileSystem;

String get _pubPackageRoot => '.';

String get gsdeployDartScript {
  final pkg = PubPackage(_pubPackageRoot);
  return join(pkg.path, 'bin', 'gsdeploy.dart');
}

FileSystemTestContext ctx = fileSystemTestContextIo;
FileSystem fs = ctx.fs;

void main() {
  //defineTests(ctx);
  //useVMConfiguration();
  group('bin_gsdeploy', () {
    test('deploy_1_file', () async {
      var top = await ctx.prepare() as Directory;
      //Directory
      final dir = Directory(join(top.path, 'dir'));
      final file = File(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);

      final gsDst =
          'gs://gstest.tekartik.com/dev/tekartik_deploy/test/deploy_1_file';
      final cmd = DartCmd([gsdeployDartScript, dir.path, gsDst]);
      await runCmd(cmd, verbose: true);
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
