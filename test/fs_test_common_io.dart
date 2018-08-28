// basically same as the io runner but with extra output
import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:path/path.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_io/context_io.dart';
export 'package:tekartik_fs_test/test_common.dart' show FileSystemTestContext;
export 'package:dev_test/test.dart';
export 'package:fs_shim/fs.dart';

final FileSystemTestContextIo fileSystemTestContextIo =
    new FileSystemTestContextIo();

class FileSystemTestContextIo extends FileSystemTestContext {
  final PlatformContext platform = platformContextIo;
  final FileSystemIo fs = new FileSystemIo();
  String outTopPath;

  FileSystemTestContextIo() {
    outTopPath = testOutTopPath;
  }

  String get outPath => join(outTopPath, super.outPath);
}

String get testOutTopPath => join(".dart_tool", "deploy", "test");

String get testOutPath => join(testOutTopPath, joinAll(testDescriptions));
