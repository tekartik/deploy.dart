@TestOn("vm")
import 'package:tekartik_deploy/deploy.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:path/path.dart';
import 'package:dev_test/test.dart';
//import 'package:fs_shim/fs.dart';
import 'package:fs_shim_test/test.dart';

void main() {
  //debugQuickLogging(Level.FINEST);
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  FileSystem fs = ctx.fs;


  group('deploy', () {
    setUp(() {
      // clearOutFolderSync();
    });

    test('simple entity', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.newDirectory(join(top.path, "dir"));
      Config config = new Config({});
      File file = fs.newFile(join(dir.path, "data"));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString("test");
      EntityConfig entityConfig = new EntityConfig("data");
      int count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(
          await fs
              .newFile(join(top.path, "deploy", "dir", "data"))
              .readAsString(),
          "test");
    });

    test('simple entity_rename', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.newDirectory(join(top.path, "dir"));
      Config config = new Config({});
      File file = fs.newFile(join(dir.path, "data"));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString("test");
      EntityConfig entityConfig = new EntityConfig.withDst("data", "data2");
      int count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(await fs.newFile(join(top.path, "deploy", "dir", "data")).exists(),
          isFalse);
      expect(
          await fs
              .newFile(join(top.path, "deploy", "dir", "data2"))
              .readAsString(),
          "test");
    });

    test('empty_config', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.newDirectory(join(top.path, "dir"));
      await dir.create();
      Config config = new Config({}, src: dir);
//              config.src = dir;
      // file
      File file = fs.newFile(join(dir.path, "file.txt"));
      await file.writeAsString("test", flush: true);
      //  /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/deploy/dir
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir
      int count = await deployConfig(config);
      expect(count, 1);
      expect(
          await fs
              .newFile(join(top.path, "deploy", "dir", "file.txt"))
              .readAsString(),
          "test");
    });

    test('with src and dst config', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.newDirectory(join(top.path, "dir"));
      await dir.create();
      Directory dst = fs.newDirectory(join(top.path, "new_dir"));
      Config config = new Config({}, src: dir, dst: dst);
//              config.src = dir;
      // file
      File file = fs.newFile(join(dir.path, "file.txt"));
      await file.writeAsString("test", flush: true);
      ;
      int count = await deployConfig(config);
      expect(count, 1);
      expect(
          await fs.newFile(join(dst.path, "file.txt")).readAsString(), "test");
    });
  });
}
