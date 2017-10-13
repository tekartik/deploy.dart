import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_io_utils/io_utils_import.dart';
import 'package:process_run/cmd_run.dart';

void rawGsUtilVersionSync() {
  Process.runSync('gsutil', ['--version']);
}

String _gsUtilExecutable;

void findGsUtilSync() {
  if (_gsUtilExecutable == null) {
    String gsUtilExecutable;
    if (findRawGsUtilSync()) {
      gsUtilExecutable = 'gsutil';
    } else {
      String gloudSdkDir =
          Platform.environment['TEKARTIK_GOOGLE_CLOUD_SDK_DIR'];
      if (gloudSdkDir != null) {
        gsUtilExecutable = join(gloudSdkDir, 'bin', 'gsutil');
      } else {
        stderr.writeln(
            'gsutil not found. It might be in your user path. If so please define in /etc/environment (with the proper path)');
        stderr.writeln(
            'TEKARTIK_GOOGLE_CLOUD_SDK_DIR=/opt/apps/google-cloud-sdk');
        throw 'gsutil not found';
      }
    }
    // Validate the executable
    Process.runSync(gsUtilExecutable, ['--version']);
    _gsUtilExecutable = gsUtilExecutable;
  }
}

class GsUtilCmd extends ProcessCmd {
  GsUtilCmd(String executable, List<String> arguments)
      : super(executable, arguments);
  @override
  String toString() => executableArgumentsToString('gsutil', arguments);
}

String get gsUtilExecutable {
  findGsUtilSync();
  return _gsUtilExecutable;
}

bool findRawGsUtilSync() {
  try {
    rawGsUtilVersionSync();
    return true;
  } catch (_) {}
  return false;
}
