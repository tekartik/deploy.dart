@TestOn('vm')
library tekartik_deploy.ae_deploy_test_;

import 'package:tekartik_fs_test/test_common.dart';
import 'package:test/test.dart';

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
