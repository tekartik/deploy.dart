import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'package:tekaly_file_download_web/mime_type.dart';

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
  var mimeType = filenameMimeType(src);
  var shell = Shell(verbose: verbose);
  await shell.run('gsutil cp $src $dst');
  await shell.run('gsutil -m setmeta -h "Content-Type:$mimeType" $dst');
}
