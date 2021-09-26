@TestOn('vm')
library tekartik_deploy.fs_io_deploy_test;

import 'dart:async';
import 'dart:io' as io;

import 'package:fs_shim/fs_io.dart' show unwrapIoDirectory;
import 'package:fs_shim/utils/io/entity.dart';
import 'package:fs_shim/utils/io/read_write.dart';
import 'package:path/path.dart';
import 'package:tekartik_deploy/fs_deploy.dart';

import 'fs_test_common_io.dart';

void main() {
  var ctx = FileSystemTestContextIo('fs_io_deploy');

  group('io_deploy', () {
    setUp(() {
      // clearOutFolderSync();
    });

    io.Directory top;
    io.Directory? src;
    io.Directory? dst;

    Future _prepare() async {
      top = unwrapIoDirectory(await ctx.prepare());
      src = io.Directory(join(top.path, 'src'));
      dst = io.Directory(join(top.path, 'dst'));
    }

    test('fs_deploy', () async {
      await _prepare();
      await writeString(io.File(join(src!.path, 'file')), 'test');

      final count = await fsDeploy(src: src, dst: dst);
      expect(count, 1);
      expect(await readString(childFile(dst!, 'file')), 'test');

      final files = await fsDeployListFiles(src: src);
      expect(files, hasLength(1));
      expect(relative(files[0].path, from: src!.path), 'file');
    });
  });
}
