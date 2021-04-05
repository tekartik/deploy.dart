// basically same as the io runner but with extra output
import 'package:fs_shim/src/io/io_file_system.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:tekartik_platform/context.dart';
import 'package:tekartik_platform_io/context_io.dart';

export 'package:fs_shim/fs.dart';
export 'package:tekartik_fs_test/test_common.dart' show FileSystemTestContext;
export 'package:test/test.dart';

final FileSystemTestContextIo fileSystemTestContextIo =
    FileSystemTestContextIo();

class FileSystemTestContextIo extends FileSystemTestContext {
  @override
  final PlatformContext platform = platformContextIo;
  @override
  final FileSystemIo fs = FileSystemIo();
}
