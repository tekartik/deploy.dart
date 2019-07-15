@TestOn("vm")
import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:tekartik_deploy/src/fs_deploy_impl.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:path/path.dart';
import 'package:dev_test/test.dart';
//import 'package:fs_shim/fs.dart';
import 'package:tekartik_fs_test/test_common.dart';

import 'package:fs_shim/utils/read_write.dart';
import 'package:fs_shim/utils/entity.dart';
import 'package:fs_shim/utils/copy.dart';

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

    Directory top;
    Directory src;
    Directory dst;

    Future _prepare() async {
      top = await ctx.prepare();
      src = childDirectory(top, "src");
      dst = childDirectory(top, "dst");
    }

    test('exclude', () async {
      await _prepare();
      await writeString(childFile(src, "file1"), "test");
      await writeString(childFile(src, "file2"), "test");
      TopCopy copy = TopCopy(fsTopEntity(src), fsTopEntity(dst),
          options: CopyOptions(recursive: true, exclude: ["file1"]));
      await copy.run();
      expect(await entityExists(childFile(dst, "file1")), isFalse);
      expect(await readString(childFile(dst, "file2")), "test");
    });

    test('simple entity', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");
      Config config = Config({})
        ..src = src
        ..dst = dst;
      int count = await deployConfigEntity(config, "file");
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('simple entity_link', () async {
      await _prepare();
      File _fileChild = childFile(src, "file");
      await writeString(_fileChild, "test");
      Config config = Config({})
        ..src = src
        ..dst = dst;
      int count = await deployConfigEntity(config, "file");
      expect(count, 1);
      if (fs.supportsFileLink) {
        Link link = childLink(dst, "file");
        expect(await fs.isLink(link.path), isTrue);
        String target = await link.target();
        expect(target, _fileChild.path);
        expect(_fileChild.isAbsolute, isTrue);
        expect(fs.path.isAbsolute(_fileChild.path), isTrue);
        //expect(await readString(fs.file(link.path)), "test");
      }
    });

    test('empty_config', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");
      Config config = Config({}, src: src, dst: dst);
      int count = await deployConfig(config);
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");

      List<File> files = await deployConfigListFiles(config);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src.path), "file");
      /*
      expect(
          await fs
              .file(join(top.path, "deploy", "dir", "file.txt"))
              .readAsString(),
          "test");
          */
    });

    test('fs_deploy', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");

      int count = await fsDeploy(src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('fs_deploy_no_dst', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");

      int count = await fsDeploy(src: src);
      expect(count, 1);
      expect(await readString(childFile(top, join("deploy", "src", "file"))),
          "test");
    });

    test('single_entity_config', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");
      int count = await fsDeploy(settings: {
        "files": ['file']
      }, src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('with_config_file_only', () async {
      await _prepare();
      File _fileChild = childFile(src, "file");
      await writeString(_fileChild, "test");
      File yaml = childFile(src, "pubspec.yaml");
      await writeString(yaml, '''
      files:
       - file''');
      int count = await fsDeploy(yaml: yaml);
      expect(count, 1);
      // location deploy/src if not specified
      File _dstFile = childFile(top, join("deploy", "src", "file"));
      expect(await readString(_dstFile), "test");
      if (fs.supportsFileLink) {
        Link link = fs.newLink(_dstFile.path);
        expect(await fs.isLink(link.path), isTrue);
        String target = await link.target();
        expect(target, _fileChild.path);
      }
    });

    test('with_config_file_and dst', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");
      File yaml = childFile(src, "pubspec.yaml");
      await writeString(yaml, '''
      files:
       - file''');
      int count = await fsDeploy(yaml: yaml, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");
    });

    test('simple entity', () async {
      //fsCopyDebug = true;
      Directory top = await ctx.prepare();
      Directory dir = fs.directory(join(top.path, "dir"));
      Config config = Config({});
      File file = fs.file(join(dir.path, "data"));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString("test");
      EntityConfig entityConfig = EntityConfig("data");
      int count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(
          await fs.file(join(top.path, "deploy", "dir", "data")).readAsString(),
          "test");
    });

    test('simple entity_rename', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.directory(join(top.path, "dir"));
      Config config = Config({});
      File file = fs.file(join(dir.path, "data"));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString("test");
      EntityConfig entityConfig = EntityConfig.withDst("data", "data2");
      int count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(await fs.file(join(top.path, "deploy", "dir", "data")).exists(),
          isFalse);
      expect(
          await fs
              .file(join(top.path, "deploy", "dir", "data2"))
              .readAsString(),
          "test");
    });

    test('empty_config', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.directory(join(top.path, "dir"));
      await dir.create();
      Config config = Config({}, src: dir);
//              config.src = dir;
      // file
      File file = fs.file(join(dir.path, "file.txt"));
      await file.writeAsString("test", flush: true);
      //  /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/deploy/dir
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir
      int count = await deployConfig(config);
      expect(count, 1);
      expect(
          await fs
              .file(join(top.path, "deploy", "dir", "file.txt"))
              .readAsString(),
          "test");
    });

    test('with src and dst config', () async {
      Directory top = await ctx.prepare();
      Directory dir = fs.directory(join(top.path, "dir"));
      await dir.create();
      Directory dst = fs.directory(join(top.path, "new_dir"));
      Config config = Config({}, src: dir, dst: dst);
//              config.src = dir;
      // file
      File file = fs.file(join(dir.path, "file.txt"));
      await file.writeAsString("test", flush: true);
      int count = await deployConfig(config);
      expect(count, 1);
      expect(await fs.file(join(dst.path, "file.txt")).readAsString(), "test");
    });

    group('impl', () {
      test('getDeploySrc', () async {
        try {
          getDeploySrc();
          fail('should fail');
        } on ArgumentError catch (_) {}

        Directory src =
            getDeploySrc(yaml: fs.file(fs.path.join('yaml_dir', 'toc.yaml')));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('yaml_dir'));

        src = getDeploySrc(
            yaml: fs.file(fs.path.join('yaml_dir', 'toc.yaml')),
            src: fs.directory("src"));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('src'));

        src = getDeploySrc(src: fs.directory("src"));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('src'));
      });
    });
  });
}
