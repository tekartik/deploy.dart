@TestOn('vm')
// Copyright (c) 2015, Alexandre Roux. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.
library fs_shim.fs_io_test;

import 'fs_test_common_io.dart';
import 'src_fs_deploy_test.dart' as fs_deploy;

void main() {
  var ctx = FileSystemTestContextIo('fs_io');

  group('io', () {
    // All tests
    fs_deploy.defineTests(ctx);
  });
}
