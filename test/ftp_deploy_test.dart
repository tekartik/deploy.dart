@TestOn('vm')
library;

import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_deploy/src/ftp/ftp_deploy_impl.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

//import 'package:tekartik_core/log_utils.dart';
//import 'package:path/path.dart';
//import 'package:fs_shim/fs.dart';

//<editor-fold desc='Description'>
//import 'package:fs_shim/utils/read_write.dart';
//import 'package:fs_shim/utils/entity.dart';
//import 'package:fs_shim/utils/copy.dart';
//</editor-fold>

void main() {
  defineTests();
}

Future<FtpClient?> load() async {
  var path = join('test', 'local_ftp_config.yaml');
  try {
    var content = await File(path).readAsString();
    var map = loadYaml(content);
    if (map is Map) {
      return FtpClient()..fromMap(map);
    }
  } catch (e) {
    print('$e fail to load config at $path');
  }
  return null;
}

void defineTests() {
  //FileSystem fs = ctx.fs;

  group('ftp_deploy', () {
    FtpClient? ftpClient;

    setUpAll(() async {
      ftpClient = await load();
    });
    test('quick', () async {
      if (ftpClient != null) {
        await ftpClient!.ls(remoteDir: '/');
        await ftpClient!.ls(remoteDir: '~');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('deploy', () async {
      if (ftpClient != null) {
        await ftpClient!
            .lftpDeploy(src: join('test', 'data'), dst: '/test/data');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  }, skip: !isLftpSupported);
}
