import 'package:path/path.dart';
import 'package:process_run/shell.dart';

var _mimeTypeMap = {
  'css': 'text/css',
  'dart': 'application/dart',
  'html': 'text/html',
  'ico': 'image/x-icon',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'js': 'application/javascript',
  'json': 'application/json',
  'png': 'image/png',
  'svg': 'image/svg+xml',
  'txt': 'text/plain',
  'webp': 'image/webp',
  'woff': 'application/font-woff',
  'woff2': 'application/font-woff2',
  'wasm': 'application/wasm',
  'pdf': 'application/pdf',
};

/// Copy file to google storage, if dst file name is omitted, it uses
/// the one from the source.
///
/// gsCopyFile('my/local/file', 'gs://my-bucket/file');
/// gsCopyFile('my/local/file', 'gs://my-bucket/');
Future<void> gsCopyFile(String src, String dst, {bool? verbose}) async {
  verbose ??= false;
  if (dst.endsWith('/')) {
    dst = url.join(dst, basename(src));
  }
  var ext = extension(src);
  var mimeType = _mimeTypeMap[ext.substring(1)]!;
  var shell = Shell(verbose: verbose);
  await shell.run('gsutil cp $src $dst');
  await shell.run('gsutil -m setmeta -h "Content-Type:$mimeType" $dst');
}
