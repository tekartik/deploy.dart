@TestOn('vm')
library;

import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:process_run/cmd_run.dart';
import 'package:tekartik_deploy/gs_deploy.dart';
import 'package:test/test.dart';

import 'fs_test_common_io.dart' show FileSystemTestContextIo;

//String get _pubPackageRoot => getPubPackageRootSync(testDirPath);

void main() {
  var ctx = FileSystemTestContextIo('manual_gs_deploy');

  group('gsdeploy', () {
    test('deploy_1_file', () async {
      var top = await ctx.prepare();
      //Directory
      final dir = Directory(join(top.path, 'dir'));
      final file = File(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);

      final gsDst =
          'gs://gstest.tekartik.com/dev/tekartik_deploy/test/deploy_1_file';
      final cmd = gsDeployCmd(dir.path, gsDst);
      await runCmd(cmd, verbose: true);
    });

    test('rsync_1_dir', () async {
      var top = await ctx.prepare();
      //Directory
      final dir = Directory(join(top.path, 'dir'));
      final file = File(join(dir.path, 'file'));
      await file.create(recursive: true);
      await file.writeAsString('test', flush: true);

      final gsDst =
          'gs://gstest.tekartik.com/dev/tekartik_deploy/test/rsync_1_file';
      final cmd = gsutilRsyncCmd(dir.path, gsDst, recursive: true);
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
