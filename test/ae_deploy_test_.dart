@TestOn("vm")
import 'package:tekartik_deploy/ae_deploy.dart';
//import 'package:tekartik_core/log_utils.dart';
//import 'package:path/path.dart';
import 'package:dev_test/test.dart';
//import 'package:fs_shim/fs.dart';
import 'package:fs_shim_test/test.dart';

//<editor-fold desc="Description">
//import 'package:fs_shim/utils/read_write.dart';
//import 'package:fs_shim/utils/entity.dart';
//import 'package:fs_shim/utils/copy.dart';
//</editor-fold>

void main() {
  //debugQuickLogging(Level.FINEST);
  defineTests(memoryFileSystemTestContext);
}

void defineTests(FileSystemTestContext ctx) {
  //FileSystem fs = ctx.fs;

  group('ae_deploy', () {
    test('test', () async {
      await aeDeployEmpty('tekartik-dev', 'test');
    }, timeout: new Timeout(new Duration(minutes: 5)));
  });
}
