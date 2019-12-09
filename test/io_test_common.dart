///
/// Common helper for io test
///
library tekartik.test.io_test_common;

import 'dart:io';

import 'package:dev_test/test.dart';
import 'package:path/path.dart';

export 'package:dev_test/test.dart';

// Test directory
String get testOutTopPath => join('.dart_tool', 'tekartik_deploy', outFolder);

String get testOutPath => getTestOutPath(testDescriptions);

String getTestOutPath([List<String> parts]) {
  parts ??= testDescriptions;

  return join(testOutTopPath, joinAll(parts));
}

String clearTestOutPath([List<String> parts]) {
  final outPath = getTestOutPath(parts);
  try {
    Directory(outPath).deleteSync(recursive: true);
  } catch (_) {}
  try {
    Directory(outPath).createSync(recursive: true);
  } catch (_) {}
  return outPath;
}

String dataFolder = 'data';
String outFolder = 'out';
String simpleFileName = 'filename.txt';
String simpleFileName2 = 'filename_2.txt';
String simpleContent = 'simple content';
