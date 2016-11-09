@TestOn("vm")
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.fs_io_test;

import 'package:dev_test/test.dart';
import 'package:fs_shim_test/test_io.dart';

import 'src_fs_deploy_test.dart' as fs_deploy;

class TestScript extends Script {}

String get testScriptPath => getScriptPath(TestScript);

void main() {
  FileSystemTestContext ctx =
      newIoFileSystemContext(join(dirname(testScriptPath), 'out'));

  group('io', () {
    // All tests
    fs_deploy.defineTests(ctx);
  });
}
