@TestOn('vm')
library tekartik_deploy.ae_deploy_test_;

import 'package:tekartik_fs_test/test_common.dart';

//import 'package:tekartik_core/log_utils.dart';
//import 'package:path/path.dart';
//import 'package:fs_shim/fs.dart';

//<editor-fold desc='Description'>
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
      // await aeDeployEmpty('tekartik-dev', 'test');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
