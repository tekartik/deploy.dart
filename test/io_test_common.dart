///
/// Common helper for io test
///
library tekartik.test.io_test_common;

import 'package:path/path.dart';
import 'package:dev_test/test.dart';
export 'package:dev_test/test.dart';
import 'dart:io';
import 'package:tekartik_pub/script.dart';

// This script resolver
class TestScript extends Script {}

// Test directory
String get testDirPath => dirname(getScriptPath(TestScript));
String get testOutTopPath => join(testDirPath, outFolder);
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
    new Directory(outPath).deleteSync(recursive: true);
  } catch (e) {}
  try {
    new Directory(outPath).createSync(recursive: true);
  } catch (e) {}
  return outPath;
}

String dataFolder = 'data';
String outFolder = 'out';
String simpleFileName = "filename.txt";
String simpleFileName2 = "filename_2.txt";
String simpleContent = "simple content";

String clearOutTestPath([parts]) => clearTestOutPath(parts);
