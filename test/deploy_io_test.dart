@TestOn("vm")
import 'package:tekartik_deploy/deploy_io.dart';
import 'package:tekartik_deploy/src/file_utils.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:yaml/yaml.dart';
import 'package:path/path.dart';
import "dart:io";
import 'package:dev_test/test.dart';
import 'io_test_common.dart';

void main() {
  //debugQuickLogging(Level.FINEST);
  defineTests();
}

void defineTests() {
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
}
