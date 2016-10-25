import 'package:tekartik_deploy/fs/fs_deploy.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:yaml/yaml.dart';
import 'package:dev_test/test.dart';
//import 'package:fs_shim/fs.dart';
import 'package:fs_shim_test/test.dart';

void main() {
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

    test('exclude', () {
      String list = '''
    exclude:
      - file1
      - file2
''';
      Config config = new Config(loadYaml(list));
      expect(config.exclude, ['file1', 'file2']);
    });
  });
}
