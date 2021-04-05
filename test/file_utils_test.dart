@TestOn('vm')
library tekartik_deploy.test.file_utils_tests;

import 'dart:io';

import 'package:path/path.dart' hide equals;
import 'package:tekartik_deploy/src/file_utils.dart';

import 'fs_test_common_io.dart' show fileSystemTestContextIo;
import 'io_test_common.dart';

String simpleFileName = 'filename.txt';
String simpleFileName2 = 'filename_2.txt';
String simpleContent = 'simple content';

void writeStringContentSync(String path, String content) {
  final file = File(path);
  try {
    file.writeAsStringSync(content);
  } on FileSystemException {
    final parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content);
  }
}

void main() => defineTests();

void defineTests() {
  var context = fileSystemTestContextIo;
  group('copy_file', () {
    test('copy_file_if_newer', () async {
      var dir = await context.prepare();

      final path1 = join(dir.path, simpleFileName);
      final path2 = join(dir.path, simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      var copied = await copyFileIfNewer(path1, path2);
      expect(File(path2).readAsStringSync(), equals(simpleContent));
      expect(copied, equals(1));
      return copyFileIfNewer(path1, path2).then((int copied) {
        expect(copied, equals(0));
      });
    });

    test('link_or_copy_file_if_newer', () async {
      var dir = await context.prepare();
      final path1 = join(dir.path, simpleFileName);
      final path2 = join(dir.path, simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      var copied = await linkOrCopyFileIfNewer(path1, path2);
      if (!Platform.isWindows) {
        expect(FileSystemEntity.isFileSync(path2), isTrue);
      }
      expect(File(path2).readAsStringSync(), equals(simpleContent));
      expect(copied, equals(1));
      return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
        expect(copied, equals(0));
      });
    });

    test('copy_files_if_newer', () async {
      var dir = await context.prepare();
      final sub1 = join(dir.path, 'sub1');
      final file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + '1');
      final file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + '2');
      final subSub1 = join(dir.path, 'sub1', 'sub1');
      final file3 = join(subSub1, simpleFileName);
      writeStringContentSync(file3, simpleContent + '3');

      final sub2 = join(dir.path, 'sub2');

      var copied = await copyFilesIfNewer(sub1, sub2);
      expect(copied, 3);
      // check sub
      expect(File(join(sub2, simpleFileName)).readAsStringSync(),
          equals(simpleContent + '1'));
      expect(File(join(sub2, simpleFileName2)).readAsStringSync(),
          equals(simpleContent + '2'));

      // and subSub
      expect(File(join(sub2, 'sub1', simpleFileName)).readAsStringSync(),
          equals(simpleContent + '3'));
      return copyFilesIfNewer(sub1, sub2).then((int copied) {
        expect(copied, equals(0));
      });
    });

    test('link_or_copy_if_newer_file', () async {
      var dir = await context.prepare();
      final path1 = join(dir.path, simpleFileName);
      final path2 = join(dir.path, simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      var copied = await linkOrCopyIfNewer(path1, path2);
      expect(File(path2).readAsStringSync(), equals(simpleContent));
      expect(copied, equals(1));
      return linkOrCopyIfNewer(path1, path2).then((int copied) {
        expect(copied, equals(0));
      });
    });

    test('link_or_copy_if_newer_dir', () async {
      var dir = await context.prepare();
      final sub1 = join(dir.path, 'sub1');
      final file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + '1');

      final sub2 = join(dir.path, 'sub2');

      var copied = await linkOrCopyIfNewer(sub1, sub2);
      expect(copied, equals(1));
      // check sub
      expect(File(join(sub2, simpleFileName)).readAsStringSync(),
          equals(simpleContent + '1'));

      return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
        expect(copied, equals(0));
      });
    });

    test('deployEntityIfNewer', () async {
      var dir = await context.prepare();
      final sub1 = join(dir.path, 'sub1');
      final file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + '1');
      final file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + '2');

      final sub2 = join(dir.path, 'sub2');

      await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(File(join(sub2, simpleFileName)).readAsStringSync(),
          equals(simpleContent + '1'));

      final copied = await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(copied, equals(0));
    });
  });

  group('symlink', () {
    // new way to link a dir (work on linux/windows
    test('link_dir', () async {
      var dir = await context.prepare();
      final sub1 = join(dir.path, 'sub1');
      final file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent);

      final sub2 = join(dir.path, 'sub2');
      await linkDir(sub1, sub2).then((count) async {
        expect(FileSystemEntity.isLinkSync(sub2), isTrue);
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isDirectorySync(sub2), isTrue);
        }
        expect(count, equals(1));

        // 2nd time nothing is done
        await linkDir(sub1, sub2).then((count) {
          expect(count, equals(0));
        });
      });
    });

    test('create file symlink', () async {
      // file symlink not supported on windows
      if (Platform.isWindows) {
        return null;
      }
      var dir = await context.prepare();

      final path1 = join(dir.path, simpleFileName);
      final path2 = join(dir.path, simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      var result = await linkFile(path1, path2);
      expect(result, 1);
      expect(File(path2).readAsStringSync(), equals(simpleContent));
    });
//
//    test('create dir symlink', () {
//      if (Platform.isWindows) {
//        return null;
//      }
//
//      Directory inDir = new Directory(scriptDirPath).parent;
//      Directory outDir = outDataDir;
//
//      return fu.createSymlink(inDir, outDir, 'packages').then((int result) {
//        expect(fu.file(outDir, 'packages/browser/dart.js').existsSync(), isTrue);
//
//      });
//    });
//
//
//
//
//    });
  });
}
