@TestOn('vm')
library;

import 'dart:io' as io;

import 'package:fs_shim/fs_memory.dart';
import 'package:path/path.dart';
import 'package:process_run/shell.dart' show shellArgument;
import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:tekartik_deploy/src/file_utils.dart';
import 'package:tekartik_deploy/src/ftp/ftp_deploy_impl.dart';
import 'package:tekartik_deploy/src/gs/gs_deploy.dart';
import 'package:tekartik_deploy/src/gs/gs_gzip.dart';
import 'package:test/test.dart';

void main() {
  late io.Directory top;
  setUp(() async {
    top = await io.Directory.systemTemp.createTemp('deploy_regression');
  });
  tearDown(() async {
    await top.delete(recursive: true);
  });

  group('regression', () {
    test('gzip every file before completing', () async {
      var dir = join(top.path, 'gzip');
      var content = List.filled(20000, 'hello world ').join();
      for (var i = 0; i < 20; i++) {
        await io.File(
          join(dir, 'sub', 'f$i.js'),
        ).create(recursive: true).then((file) => file.writeAsString(content));
      }
      await gzipDirectoryInPlace(dir);
      for (var i = 0; i < 20; i++) {
        var bytes = await io.File(join(dir, 'sub', 'f$i.js')).readAsBytes();
        // gzip magic
        expect(bytes.take(2), [0x1f, 0x8b]);
        expect(io.gzip.decode(bytes).length, content.length);
      }
    });

    test('copyFilesIfNewer errors', () async {
      var src = join(top.path, 'src');
      var dst = join(top.path, 'dst');
      await io.File(join(src, 'a.txt')).create(recursive: true);
      // The destination file is a directory: the copy fails
      await io.Directory(join(dst, 'a.txt')).create(recursive: true);
      await expectLater(
        copyFilesIfNewer(src, dst).timeout(const Duration(seconds: 10)),
        throwsA(isA<io.FileSystemException>()),
      );
      await expectLater(
        copyFilesIfNewer(
          join(top.path, 'missing'),
          dst,
        ).timeout(const Duration(seconds: 10)),
        throwsA(isA<io.FileSystemException>()),
      );
    });

    test('copyFilesIfNewer count', () async {
      var src = join(top.path, 'src');
      var dst = join(top.path, 'dst');
      for (var path in ['a.txt', join('b', 'c.txt')]) {
        await io.File(
          join(src, path),
        ).create(recursive: true).then((file) => file.writeAsString(path));
      }
      expect(await copyFilesIfNewer(src, dst), 2);
      expect(
        await io.File(join(dst, 'b', 'c.txt')).readAsString(),
        join('b', 'c.txt'),
      );
      expect(await copyFilesIfNewer(src, dst), 0);
    });

    test('deployEntity sub path', () async {
      var fs = newFileSystemMemory();
      var src = fs.directory('/top/src');
      var dst = fs.directory('/top/dst');
      await fs.file('/top/src/sub/file').create(recursive: true);
      await fs.file('/top/src/sub/file').writeAsString('test');
      var config = Config({})
        ..src = src
        ..dst = dst;
      expect(await deployEntity(config, EntityConfig('sub/file')), 1);
      expect(await fs.file('/top/dst/sub/file').readAsString(), 'test');
      expect(await fs.file('/top/dst/file').exists(), isFalse);

      expect(
        await deployEntity(config, EntityConfig.withDst('sub/file', 'out/f')),
        1,
      );
      expect(await fs.file('/top/dst/out/f').readAsString(), 'test');
    });

    test('lftp script', () {
      var client = FtpClient()
        ..host = 'h'
        ..port = 21
        ..username = 'u'
        ..password = 'p';
      var script = ftpClientLftpScript(client, 'ls dir');
      expect(script, contains('lftp sftp://u:p@h:21 -e "ls dir ; quit"'));
      expect(script, isNot(contains('}')));

      client
        ..port = null
        ..allowUnsecure = true;
      expect(
        ftpClientLftpScript(client, 'ls dir'),
        contains('lftp ftp://u:p@h -e "set ftp:ssl-allow no ; ls dir ; quit"'),
      );
      expect(
        ftpClientLftpScript(client, 'ls dir', hidePassword: true),
        allOf(contains('ftp://u:****@h '), isNot(contains(':p@'))),
      );
    });

    test('gsutil cp arguments quoted', () {
      var scripts = gsCopyFileScripts('my dir/file.txt', 'gs://bucket/');
      expect(scripts, [
        'gsutil cp ${shellArgument('my dir/file.txt')} gs://bucket/file.txt',
        'gsutil -m setmeta -h Content-Type:text/plain gs://bucket/file.txt',
      ]);
      expect(scripts.first, isNot(contains(' my dir/file.txt')));
    });
  });
}
