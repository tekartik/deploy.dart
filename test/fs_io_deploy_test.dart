@TestOn("vm")
import 'package:tekartik_deploy/fs_deploy.dart';
//import 'package:tekartik_core/log_utils.dart';
import 'package:path/path.dart';
import 'package:dev_test/test.dart';
//import 'package:fs_shim/fs.dart';
//import 'package:fs_shim_test/test.dart';
import 'dart:io';
import 'dart:async';
import 'package:fs_shim/fs_io.dart' show unwrapIoDirectory;
import 'package:fs_shim/utils/io/read_write.dart';
import 'package:fs_shim/utils/io/entity.dart';

import 'package:fs_shim_test/test_io.dart' show newIoFileSystemContext, Script, getScriptPath, FileSystemTestContext, FileSystem;


class TestScript extends Script {}

String get testScriptPath => getScriptPath(TestScript);

void main() {

  FileSystemTestContext ctx = newIoFileSystemContext(join(dirname(testScriptPath), 'out'));

  group('io_deploy', () {
    setUp(() {
      // clearOutFolderSync();
    });

    Directory top;
    Directory src;
    Directory dst;

    Future _prepare() async {
      top = unwrapIoDirectory(await ctx.prepare());
      src = childDirectory(top, "src");
      dst = childDirectory(top, "dst");
    }

    test('fs_deploy', () async {
      await _prepare();
      await writeString(childFile(src, "file"), "test");

      int count = await fsDeploy(src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst, "file")), "test");

      List<File> files = await fsDeployListFiles(src: src);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src.path), "file");
    });

  });
}
