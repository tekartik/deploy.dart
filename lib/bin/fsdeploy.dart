import 'dart:async';

import 'package:args/args.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
import 'package:tekartik_deploy/src/file_utils.dart';
import 'package:yaml/yaml.dart';

const String flagHelp = 'help';
// ignore_for_file: avoid_slow_async_io

Future _deployEntity(String src, String dst) async {
  var isDir = await FileSystemEntity.isDirectory(src);
  if (isDir) {
    //fu.copyFilesIfNewer(src_, dst_);
    //return fu.linkDir(src_, dst_);
    return linkOrCopyFilesInDirIfNewer(src, dst, recursive: true);
  } else {
    var isFile = await FileSystemEntity.isFile(src);
    if (isFile) {
      return linkOrCopyFileIfNewer(src, dst);
    } else {
      throw '${src} entity not found';
    }
  }
}

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

Future main(List<String> arguments) async {
  //debugQuickLogging(Level.FINE);

  final parser = ArgParser(allowTrailingOptions: true);
  parser.addFlag(flagHelp, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag('dir',
      abbr: 'd',
      help: 'Deploy a directory as is, even if no deploy.yaml is present',
      negatable: false);
  parser.addFlag('version',
      help: 'Display the script version', negatable: false);

  final _argsResult = parser.parse(arguments);

  void _usage() {
    stdout.writeln('Deploy from build to deploy folder from a top pub package');
    stdout.writeln('');
    stdout.writeln('  ${currentScriptName} [project_dir]');
    stdout.writeln('');
    stdout.writeln('or from a given folder to another one');
    stdout.writeln('');
    stdout.writeln(
        '  ${currentScriptName} <dir_containing_deploy_yaml> destination_dir>');
    stdout
        .writeln('  ${currentScriptName} <deploy_file.yaml> <destination_dir>');
    stdout.writeln(
        '  ${currentScriptName} <deploy_file.yaml> <source_dir> <destination_dir>');
    stdout.writeln();
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

  if (_argsResult.rest.length > 3) {
    _usage();
    return null;
  }

  var dirOnly = _argsResult['dir'] as bool;

  String srcDir;
  String dstDir;

  Future _deploy(Map settings, String dir) {
    print(dir);
    print(settings);

    // first delete destination
    final buildDir = normalize(join(srcDir, dir));
    final deployDir = normalize(join(dstDir, dir));

    emptyOrCreateDirSync(deployDir);
    final futures = <Future>[];
    for (var fileOrDirRaw in settings['files'] as List) {
      var fileOrDir = fileOrDirRaw.toString();
      print(fileOrDir);
      futures.add(
          _deployEntity(join(buildDir, fileOrDir), join(deployDir, fileOrDir)));
    }
    return Future.wait(futures);
  }

  /*
  Future _handleYaml(String dir, String yamlFilePath) {
    return new File(yamlFilePath).readAsString().then((content) {
      var doc = loadYaml(content);
      if (doc is YamlMap) {
        return _deploy(doc, relative(dir, from: srcDir)).then((_) {
          return 1;
        });
      }
      return 0;
    });
  }
  */

  Future<int> _handleDir(String dir) async {
    // this is a directoru
    final deployYaml = 'deploy.yaml';

    return await (FileSystemEntity.isDirectory(dir)).then((bool isDir) {
      //print('dir $dir: ${isDir}');
      if (isDir) {
        final deployYamlPath = join(dir, deployYaml);
        //devPrint(dir);
        return FileSystemEntity.isFile(deployYamlPath)
            .then((bool containsDeployYaml) async {
          //print('gitFile $gitFile: ${containsDotGit}');
          if (containsDeployYaml) {
            //gitPull(dir);
            return await File(deployYamlPath)
                .readAsString()
                .then((content) async {
              var doc = loadYaml(content);
              if (doc is YamlMap) {
                await _deploy(doc, relative(dir, from: srcDir));
                return 1;
              }
              return 0;
            });
          } else {
            final sub = <Future<int>>[];

            return Directory(dir)
                .list()
                .listen((FileSystemEntity fse) {
                  sub.add(_handleDir(fse.path));
                })
                .asFuture()
                .then((_) {
                  return Future.wait(sub).then((List<int> results) {
                    var count = 0;
                    results.forEach((int value) {
                      count += value;
                    });
                    return count;
                  });
                });
          }
        });
      }
      return 0;
    });
  }

  // new implementation
  Future _newDeploy(Map settings) async {
    final config = Config(settings,
        src: Directory(srcDir), dst: dstDir == null ? null : Directory(dstDir));

    return await deployConfig(config);
  }

  // int argIndex = 0;
  // Handle direct yaml file
  if (_argsResult.rest.isNotEmpty) {
    final firstArg = _argsResult.rest[0];

    // First arg can specify a file and the default src directory
    if (firstArg.endsWith('.yaml')) {
      final yamlFileName = firstArg;
      final yamlFilePath = normalize(absolute(yamlFileName));
      srcDir = dirname(yamlFilePath);

      if (_argsResult.rest.length > 1) {
        srcDir = normalize(absolute(_argsResult.rest[1]));
        if (_argsResult.rest.length > 2) {
          dstDir = normalize(absolute(_argsResult.rest[2]));
        }
      }

      final content = await File(yamlFilePath).readAsString();

      var settings = loadYaml(content) as Map;
      return await _newDeploy(settings);
    }

    if (dirOnly) {
      srcDir = firstArg;
      if (_argsResult.rest.length > 1) {
        dstDir = normalize(absolute(_argsResult.rest[1]));
      }
      return await _newDeploy({});
    }
  }

  // Regular dart build
  if (_argsResult.rest.length < 2) {
    final dir =
        _argsResult.rest.isEmpty ? Directory.current.path : _argsResult.rest[0];

    // try root
    srcDir = dir;
    dstDir = join(srcDir, 'deploy');
    final count = await _handleDir(srcDir);

    if (count == 0) {
      print('no deploy.yaml file found in ${srcDir}');
      srcDir = join(dir, 'build');
      dstDir = join(srcDir, 'deploy');

      // check where build exists first
      if (await Directory(srcDir).exists()) {
        var count = await _handleDir(srcDir);
        if (count == 0) {
          // Try to handle root
          // what is runned when using fsdeploy in a folder
          count = await _handleDir(dir);
          if (count == 0) {
            print('no deploy.yaml file found in ${srcDir} nor ${dir}');
          }
        }
      }
    }
  } else {
//    String firstArg = _argsResult.rest[0];

//    // First arg can specify a file and the default src directory
//    if (firstArg.endsWith('.yaml')) {
//      String yamlFileName = firstArg;
//      //srcDir
//      srcDir = _argsResult.rest[1];
//      if (_argsResult.rest.length > 2) {
//        dstDir = _argsResult.rest[2];
//      }
//      return new File(yamlFilePath).readAsString().then((content) {
//
//           var doc = loadYaml(content);
//    } else {
    srcDir = _argsResult.rest[0];
    dstDir = _argsResult.rest[1];
    //}

    await _handleDir(srcDir).then((count) {
      if (count == 0) {
        print('no deploy.yaml file found in ${srcDir}');
      }
    });
  }
  return null;
}
