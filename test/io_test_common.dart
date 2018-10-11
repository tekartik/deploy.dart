///
/// Common helper for io test
///
library tekartik.test.io_test_common;

import 'package:path/path.dart';
import 'package:dev_test/test.dart';
export 'package:dev_test/test.dart';
import 'dart:io';

// Test directory
String get testOutTopPath => join('.dart_tool', 'tekartik_deploy', outFolder);
String get testOutPath => getTestOutPath(testDescriptions);

String getTestOutPath([List<String> parts]) {
  if (parts == null) {
    parts = testDescriptions;
  }
  return join(testOutTopPath, joinAll(parts));
}

String clearTestOutPath([List<String> parts]) {
  String outPath = getTestOutPath(parts);
  try {
    Directory(outPath).deleteSync(recursive: true);
  } catch (e) {}
  try {
    Directory(outPath).createSync(recursive: true);
  } catch (e) {}
  return outPath;
}

String dataFolder = 'data';
String outFolder = 'out';
String simpleFileName = "filename.txt";
String simpleFileName2 = "filename_2.txt";
String simpleContent = "simple content";
