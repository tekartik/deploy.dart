import 'dart:io';

/// Gzip every file of a directory in place, completes when all are written.
Future<void> gzipDirectoryInPlace(String src) async {
  var entities = await Directory(src).list(recursive: true).toList();
  await Future.wait(
    entities.map((fse) async {
      // ignore: avoid_slow_async_io
      if (await FileSystemEntity.isFile(fse.path)) {
        final file = File(fse.path);
        final data = gzip.encode(await file.readAsBytes());
        // Delete first, the file might be a link to the source
        await file.delete();
        await file.writeAsBytes(data);
      }
    }),
  );
}
