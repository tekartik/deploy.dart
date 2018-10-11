@TestOn("vm")
library tekartik_deploy.test.file_utils_tests;

import 'package:tekartik_deploy/src/file_utils.dart';
import 'package:path/path.dart' hide equals;
import 'io_test_common.dart';

import 'dart:io';

String simpleFileName = "filename.txt";
String simpleFileName2 = "filename_2.txt";
String simpleContent = "simple content";

// get output filename in the data/out folder
// really not safe
String outDataFilenamePath(String filename) => join(testOutPath, filename);

// get input filename in the data folder
// really not safe
//String inDataFilenamePath(String filename) => join(dataPath, filename);

void writeStringContentSync(String path, String content) {
  File file = File(path);
  try {
    file.writeAsStringSync(content);
  } on FileSystemException {
    Directory parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content);
  }
}

void main() => defineTests();

void defineTests() {
  group('copy_file', () {
    test('copy_file_if_newer', () {
      clearTestOutPath();
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      return copyFileIfNewer(path1, path2).then((int copied) {
        expect(File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return copyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_file_if_newer', () {
      clearTestOutPath();
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);

      writeStringContentSync(path1, simpleContent);

      return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
        if (!Platform.isWindows) {
          expect(FileSystemEntity.isFileSync(path2), isTrue);
        }
        expect(File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return linkOrCopyFileIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('copy_files_if_newer', () {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");
      String file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + "2");
      String subSub1 = outDataFilenamePath(join('sub1', 'sub1'));
      String file3 = join(subSub1, simpleFileName);
      writeStringContentSync(file3, simpleContent + "3");

      String sub2 = outDataFilenamePath('sub2');

      return copyFilesIfNewer(sub1, sub2).then((int copied) {
        // check sub
        expect(File(join(sub2, simpleFileName)).readAsStringSync(),
            equals(simpleContent + "1"));
        expect(File(join(sub2, simpleFileName2)).readAsStringSync(),
            equals(simpleContent + "2"));

        // and subSub
        expect(File(join(sub2, 'sub1', simpleFileName)).readAsStringSync(),
            equals(simpleContent + "3"));
        return copyFilesIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_file', () {
      clearTestOutPath();
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      return linkOrCopyIfNewer(path1, path2).then((int copied) {
        expect(File(path2).readAsStringSync(), equals(simpleContent));
        expect(copied, equals(1));
        return linkOrCopyIfNewer(path1, path2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('link_or_copy_if_newer_dir', () {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");

      String sub2 = outDataFilenamePath('sub2');

      return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
        expect(copied, equals(1));
        // check sub
        expect(File(join(sub2, simpleFileName)).readAsStringSync(),
            equals(simpleContent + "1"));

        return linkOrCopyIfNewer(sub1, sub2).then((int copied) {
          expect(copied, equals(0));
        });
      });
    });

    test('deployEntityIfNewer', () async {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent + "1");
      String file2 = join(sub1, simpleFileName2);
      writeStringContentSync(file2, simpleContent + "2");

      String sub2 = outDataFilenamePath('sub2');

      await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(File(join(sub2, simpleFileName)).readAsStringSync(),
          equals(simpleContent + "1"));

      int copied = await deployEntitiesIfNewer(
          sub1, sub2, [simpleFileName, simpleFileName2]);
      expect(copied, equals(0));
    });
  });

  group('symlink', () {
    // new way to link a dir (work on linux/windows
    test('link_dir', () async {
      clearTestOutPath();
      String sub1 = outDataFilenamePath('sub1');
      String file1 = join(sub1, simpleFileName);
      writeStringContentSync(file1, simpleContent);

      String sub2 = outDataFilenamePath('sub2');
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
      clearTestOutPath();
      // file symlink not supported on windows
      if (Platform.isWindows) {
        return null;
      }
      String path1 = outDataFilenamePath(simpleFileName);
      String path2 = outDataFilenamePath(simpleFileName2);
      writeStringContentSync(path1, simpleContent);

      await linkFile(path1, path2).then((int result) {
        expect(result, 1);
        expect(File(path2).readAsStringSync(), equals(simpleContent));
      });
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
