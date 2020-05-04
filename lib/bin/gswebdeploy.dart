#!/usr/bin/env dart

import 'dart:async';

import 'package:args/args.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_deploy/gs_deploy.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'package:tekartik_deploy/src/gsutil.dart';

const String flagHelp = 'help';

String get currentScriptName => basenameWithoutExtension(Platform.script.path);
String checkFlag = 'check';

Future main(List<String> arguments) async {
  //debugQuickLogging(Level.FINE);

  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('version',
      help: 'Display the script version', negatable: false);
  parser.addFlag(checkFlag,
      help: 'Check if gsutil is installed', negatable: false);

  final _argsResult = parser.parse(arguments);

  void _usage() {
    stdout.writeln('Deploy from source (local) to remote destination (gs://');
    stdout.writeln('');
    print('  ${currentScriptName} /my/folder gs://my.bucket/my_folder');
    stdout.writeln('');

    stdout.writeln(parser.usage);
  }

  var help = _argsResult[flagHelp] as bool;
  if (help) {
    _usage();
    return null;
  }

  if (_argsResult['version'] as bool) {
    stdout.writeln('${currentScriptName} ${version}');
    return null;
  }

  var check = _argsResult[checkFlag] as bool;
  if (check) {
    try {
      findGsUtilSync();
    } catch (_) {
      exit(1);
    }
    exit(0);
  }

  if (_argsResult.rest.length != 2) {
    _usage();
    return null;
  }

  final src = _argsResult.rest[0];
  final dst = _argsResult.rest[1];
//  String DST_FOLDER = 'gs://gstest.tekartik.com/milomedy/';
//
//  setupQuickLogging(Level.FINE);
//  String buildPath = APPENGINE_APP_DEPLOY_TOP;
//
  await gsWebDeploy(src, dst);
}
