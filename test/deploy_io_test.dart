@TestOn("vm")
import 'package:path/path.dart';
//import "dart:io";
import 'package:dev_test/test.dart';
import 'io_test_common.dart';

import 'package:fs_shim_test/test_io.dart';
//import 'package:fs_shim/fs_io.dart';
import 'deploy_test.dart' as deploy_test;

class TestScript extends Script {}

String get testScriptPath => getScriptPath(TestScript);
String top = join(dirname(testScriptPath), 'out');
FileSystemTestContext ctx = newIoFileSystemContext(top);

main() {
  defineTests(ctx);

  group('raw', () {
    test('dir', () async {
      Directory top = await ctx.prepare();
      //Directory
      Directory dir = new Directory(join(top.path, 'dir'));
      expect(dir.path, join(top.path, 'dir'));
    });
  });
}

void defineTests(FileSystemTestContext ctx) {
  group('io', () {
    deploy_test.defineTests(ctx);
  });
  /*
  group('config', () {
    test('empty', () {
      Config config = new Config({});
      expect(config.entities, isEmpty);
      expect(config.src, isNull);
      expect(config.dst, isNull);
    });

    test('list', () {
      String list = '''
    files:
      - file1
      - file2
''';
      Config config = new Config(loadYaml(list));
      expect(config.entities.length, 2);
      expect(config.entities[0].src, "file1");
      expect(config.entities[1].src, "file2");
    });

    test('map', () {
      String list = '''
    files:
      file1:
      file2:
''';
      Config config = new Config(loadYaml(list));
      expect(config.entities.length, 2);
      // order not respected here
      if (config.entities[0].src == "file1") {
        expect(config.entities[1].src, "file2");
      } else {
        expect(config.entities[1].src, "file1");
        expect(config.entities[0].src, "file2");
      }
    });

    test('dst', () {
      String list = '''
    files:
      - file1: file1dst
''';
      Config config = new Config(loadYaml(list));
      expect(config.entities.length, 1);
      expect(config.entities[0].src, "file1");
      expect(config.entities[0].dst, "file1dst");
    });
  });

  group('deploy', () {
    setUp(() {
      // clearOutFolderSync();
    });

    test('simple entity', () {
      clearTestOutPath();
      Config config = new Config({});
      String dir = join(testOutPath, "my_data");
      config.src = dir;
      writeStringContentSync(join(dir, simpleFileName), simpleContent);
      EntityConfig entityConfig = new EntityConfig(simpleFileName);
      return deployEntity(config, entityConfig).then((int count) {
        expect(count, 1);
        expect(
            new File(join(testOutPath, "deploy", "my_data", simpleFileName))
                .readAsStringSync(),
            simpleContent);
      });
    });

    test('simple entity rename', () {
      clearTestOutPath();
      Config config = new Config({});
      String dir = join(testOutPath, "my_data");
      config.src = dir;
      writeStringContentSync(join(dir, simpleFileName), simpleContent);
      EntityConfig entityConfig =
          new EntityConfig.withDst(simpleFileName, simpleFileName2);
      return deployEntity(config, entityConfig).then((int count) {
        expect(count, 1);
        expect(
            new File(join(testOutPath, "deploy", "my_data", simpleFileName))
                .existsSync(),
            false);
        expect(
            new File(join(testOutPath, "deploy", "my_data", simpleFileName2))
                .readAsStringSync(),
            simpleContent);
      });
    });

    test('empty config', () {
      clearTestOutPath();
      Config config = new Config({}, src: join(testOutPath, "my_data"));
//              config.src = dir;
      // file
      writeStringContentSync(join(config.src, simpleFileName), simpleContent);
      return deployConfig(config).then((int count) {
        expect(count, 1);
        expect(
            new File(join(testOutPath, "deploy", "my_data", simpleFileName))
                .readAsStringSync(),
            simpleContent);
      });
    });

    test('with src and dst config', () {
      clearTestOutPath();
      String dst = join(testOutPath, "my_new_data");
      Config config =
          new Config({}, src: join(testOutPath, "my_data"), dst: dst);
//              config.src = dir;
      // file
      writeStringContentSync(join(config.src, simpleFileName), simpleContent);
      return deployConfig(config).then((int count) {
        expect(count, 1);
        expect(new File(join(dst, simpleFileName)).readAsStringSync(),
            simpleContent);
      });
    });

  });
      */
}
