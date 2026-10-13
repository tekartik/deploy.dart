import 'package:path/path.dart';
import 'package:process_run/shell.dart';

import 'package:tekartik_app_media/mime_type.dart';

/// Copy file to google storage, if dst file name is omitted, it uses
/// the one from the source.
///
/// gsCopyFile('my/local/file', 'gs://my-bucket/file');
/// gsCopyFile('my/local/file', 'gs://my-bucket/');
Future<void> gsCopyFile(String src, String dst, {bool? verbose}) async {
  verbose ??= false;
  var shell = Shell(verbose: verbose);
  for (var script in gsCopyFileScripts(src, dst)) {
    await shell.run(script);
  }
}

/// The gsutil commands run by [gsCopyFile], arguments quoted.
List<String> gsCopyFileScripts(String src, String dst) {
  if (dst.endsWith('/')) {
    dst = url.join(dst, basename(src));
  }
  var mimeType = filenameMimeType(src);
  var header = shellArgument('Content-Type:$mimeType');
  return [
    'gsutil cp ${shellArgument(src)} ${shellArgument(dst)}',
    'gsutil -m setmeta -h $header ${shellArgument(dst)}',
  ];
}
