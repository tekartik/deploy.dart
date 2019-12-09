import 'dart:io';

import 'package:process_run/shell.dart';
import 'package:pub_semver/pub_semver.dart';

Version parsePlatformVersion(String text) {
  return Version.parse(text.split(' ').first);
}

Future main() async {
  var shell = Shell();

  await shell.run('''
  dartfmt -n . --set-exit-if-changed
  dartanalyzer --fatal-warnings --fatal-infos . 
  pub run test -p vm,chrome
  ''');

  var dartVersion = parsePlatformVersion(Platform.version);
  if (dartVersion >= Version(2, 4, 0, pre: 'dev')) {
    await shell.run('''
    pub run build_runner test -- -p vm
  ''');
  }
}
