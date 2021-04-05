import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:tekartik_deploy/src/fs_deploy_impl.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';
//import 'package:fs_shim/fs.dart';

import 'package:fs_shim/utils/read_write.dart';
import 'package:fs_shim/utils/entity.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:tekartik_fs_test/test_common.dart';

void main() {
  //debugQuickLogging(Level.FINEST);
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  final fs = ctx.fs;

  late Directory top;
  Directory? src;
  Directory? dst;

  Future _prepare() async {
    top = await ctx.prepare();
    src = childDirectory(top, 'src');
    dst = childDirectory(top, 'dst');
  }

  group('fs_deploy', () {
    test('fs_deploy', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');

      final count = await fsDeploy(src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');
    });

    test('fs_deploy_no_dst', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');

      final count = await fsDeploy(src: src);
      expect(count, 1);
      expect(await readString(childFile(top, join('deploy', 'src', 'file'))),
          'test');
    });

    test('single_entity_config', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');
      final count = await fsDeploy(settings: {
        'files': ['file']
      }, src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');
    });

    test('with_config_file_only', () async {
      await _prepare();
      final _fileChild = childFile(src!, 'file');
      await writeString(_fileChild, 'test');
      final yaml = childFile(src!, 'pubspec.yaml');
      await writeString(yaml, '''
      files:
       - file''');
      final count = await fsDeploy(yaml: yaml);
      expect(count, 1);
      // location deploy/src if not specified
      final _dstFile = childFile(top, join('deploy', 'src', 'file'));
      expect(await readString(_dstFile), 'test');
      if (fs.supportsFileLink) {
        final link = fs.link(_dstFile.path);
        expect(await fs.isLink(link.path), isTrue);
        final target = await link.target();
        expect(target, _fileChild.path);
      }
    });

    test('with_config_file_only_nosymlink', () async {
      await _prepare();
      final _fileChild = childFile(src!, 'file');
      await writeString(_fileChild, 'test');
      final yaml = childFile(src!, 'pubspec.yaml');
      await writeString(yaml, '''
      files:
       - file''');
      final count =
          await fsDeploy(options: fsDeployOptionsNoSymLink, yaml: yaml);
      expect(count, 1);
      // location deploy/src if not specified
      final _dstFile = childFile(top, join('deploy', 'src', 'file'));
      expect(await readString(_dstFile), 'test');
      if (fs.supportsFileLink) {
        final path = _dstFile.path;
        expect(await fs.isLink(path), isFalse);
        expect(await fs.isFile(path), isTrue);
      }
    });

    test('with_config_file_and dst', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');
      final yaml = childFile(src!, 'pubspec.yaml');
      await writeString(yaml, '''
      files:
       - file''');
      final count = await fsDeploy(yaml: yaml, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');
    });
  });
  group('deploy', () {
    setUp(() {
      // clearOutFolderSync();
    });

    test('exclude', () async {
      await _prepare();
      await writeString(childFile(src!, 'file1'), 'test');
      await writeString(childFile(src!, 'file2'), 'test');
      final copy = TopCopy(fsTopEntity(src!), fsTopEntity(dst!),
          options: CopyOptions(recursive: true, exclude: ['file1']));
      await copy.run();
      expect(await entityExists(childFile(dst!, 'file1')), isFalse);
      expect(await readString(childFile(dst!, 'file2')), 'test');
    });

    test('simple entity', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');
      final config = Config({})
        ..src = src
        ..dst = dst;
      final count = await deployConfigEntity(config, 'file');
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');
    });

    test('simple entity_link', () async {
      await _prepare();
      final _fileChild = childFile(src!, 'file');
      await writeString(_fileChild, 'test');
      final config = Config({})
        ..src = src
        ..dst = dst;
      final count = await deployConfigEntity(config, 'file');
      expect(count, 1);
      if (fs.supportsFileLink) {
        final link = childLink(dst!, 'file');
        expect(await fs.isLink(link.path), isTrue);
        final target = await link.target();
        expect(target, _fileChild.path);
        expect(_fileChild.isAbsolute, isTrue);
        expect(fs.path.isAbsolute(_fileChild.path), isTrue);
        //expect(await readString(fs.file(link.path)), 'test');
      }
    });

    test('empty_config', () async {
      await _prepare();
      await writeString(childFile(src!, 'file'), 'test');
      final config = Config({}, src: src, dst: dst);
      final count = await deployConfig(config);
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');

      final files = await deployConfigListFiles(config);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src!.path), 'file');
      /*
      expect(
          await fs
              .file(join(top.path, 'deploy', 'dir', 'file.txt'))
              .readAsString(),
          'test');
          */
    });

    test('simple entity', () async {
      //fsCopyDebug = true;
      final top = await ctx.prepare();
      final dir = fs.directory(join(top.path, 'dir'));
      final config = Config({});
      final file = fs.file(join(dir.path, 'data'));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString('test');
      final entityConfig = EntityConfig('data');
      final count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(
          await fs.file(join(top.path, 'deploy', 'dir', 'data')).readAsString(),
          'test');
    });

    test('simple entity_rename', () async {
      final top = await ctx.prepare();
      final dir = fs.directory(join(top.path, 'dir'));
      final config = Config({});
      final file = fs.file(join(dir.path, 'data'));
      config.src = dir;
      await file.create(recursive: true);
      await file.writeAsString('test');
      final entityConfig = EntityConfig.withDst('data', 'data2');
      final count = await deployEntity(config, entityConfig);
      expect(count, 1);
      expect(await fs.file(join(top.path, 'deploy', 'dir', 'data')).exists(),
          isFalse);
      expect(
          await fs
              .file(join(top.path, 'deploy', 'dir', 'data2'))
              .readAsString(),
          'test');
    });

    test('empty_config', () async {
      final top = await ctx.prepare();
      final dir = fs.directory(join(top.path, 'dir'));
      await dir.create();
      final config = Config({}, src: dir);
//              config.src = dir;
      // file
      final file = fs.file(join(dir.path, 'file.txt'));
      await file.writeAsString('test', flush: true);
      //  /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/deploy/dir
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir/file.txt
      // /media/ssd/devx/git/github.com/tekartik/tekartik_deploy.dart/test/out/io/deploy/empty_config/dir
      final count = await deployConfig(config);
      expect(count, 1);
      expect(
          await fs
              .file(join(top.path, 'deploy', 'dir', 'file.txt'))
              .readAsString(),
          'test');
    });

    test('with src and dst config', () async {
      final top = await ctx.prepare();
      final dir = fs.directory(join(top.path, 'dir'));
      await dir.create();
      final dst = fs.directory(join(top.path, 'new_dir'));
      final config = Config({}, src: dir, dst: dst);
//              config.src = dir;
      // file
      final file = fs.file(join(dir.path, 'file.txt'));
      await file.writeAsString('test', flush: true);
      final count = await deployConfig(config);
      expect(count, 1);
      expect(await fs.file(join(dst.path, 'file.txt')).readAsString(), 'test');
    });

    group('impl', () {
      test('getDeploySrc', () async {
        try {
          getDeploySrc();
          fail('should fail');
        } on ArgumentError catch (_) {}

        var src =
            getDeploySrc(yaml: fs.file(fs.path.join('yaml_dir', 'toc.yaml')));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('yaml_dir'));

        src = getDeploySrc(
            yaml: fs.file(fs.path.join('yaml_dir', 'toc.yaml')),
            src: fs.directory('src'));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('src'));

        src = getDeploySrc(src: fs.directory('src'));

        expect(isAbsolute(src.path), isTrue);
        expect(src.path, endsWith('src'));
      });
    });
    group('FsDeployConfig', () {
      test('simple', () async {
        final top = await ctx.prepare();
        final dir = fs.directory(join(top.path, 'src'));
        await dir.create();
        final dst = fs.directory(join(top.path, 'dst'));

        final config = FsDeployConfig(
            entities: [EntityConfig.withDst('file.txt', 'file2.txt')],
            src: dir,
            dst: dst);
//              config.src = dir;
        // file
        final file = fs.file(join(dir.path, 'file.txt'));
        await file.writeAsString('test', flush: true);
        final count = await deployConfig(config);
        expect(count, 1);
        expect(
            await fs.file(join(dst.path, 'file2.txt')).readAsString(), 'test');
      });
    });
  });
}
