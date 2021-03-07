#!/usr/bin/env dart

import 'dart:async';

import 'package:args/args.dart';
import 'package:fs_shim/fs_io.dart';
import 'package:path/path.dart';
import 'package:tekartik_deploy/src/bin_version.dart';

//import 'package:yaml/yaml.dart';
//import 'package:tekartik_core/log_utils.dart';
//import 'package:tekartik_deploy/deploy_io.dart' hide Config, deployConfig;

const String flagHelp = 'help';

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
    stdout.writeln(
        '  $currentScriptName <cmd> <applicationId> <module> <template_dir>');
    stdout.writeln('');
    stdout.writeln('or from a given folder to another one');

    stdout.writeln();
    stdout.writeln(parser.usage);
  }

  var help = _argsResult[flagHelp] as bool;
  if (help) {
    _usage();
    return null;
  }

  if (_argsResult['version'] as bool) {
    stdout.writeln('$currentScriptName $version');
    return null;
  }

  if (_argsResult.rest.length > 3) {
    _usage();
    return null;
  }

  //bool debug = true;

  // await aeDeployEmpty('tekartik-dev', 'default');
  /*
  bool dirOnly = _argsResult['dir'];

  String srcDir;
  String dstDir;

  Future _deploy(Map settings, String dir) {
    print(dir);
    print(settings);

    // first delete destination
    String buildDir = normalize(join(srcDir, dir));
    String deployDir = normalize(join(dstDir, dir));

    emptyOrCreateDirSync(deployDir);
    List<Future> futures = [];
    for (String fileOrDir in settings['files']) {
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

  Future _handleDir(String dir) async {
    // this is a directoru
    String deployYaml = 'deploy.yaml';

    return (FileSystemEntity.isDirectory(dir)).then((bool isDir) {
      //print('dir $dir: ${isDir}');
      if (isDir) {
        String deployYamlPath = join(dir, deployYaml);
        //devPrint(dir);
        return FileSystemEntity
            .isFile(deployYamlPath)
            .then((bool containsDeployYaml) {
          //print('gitFile $gitFile: ${containsDotGit}');
          if (containsDeployYaml) {
            //gitPull(dir);
            return new File(deployYamlPath).readAsString().then((content) {
              var doc = loadYaml(content);
              if (doc is YamlMap) {
                return _deploy(doc, relative(dir, from: srcDir)).then((_) {
                  return 1;
                });
              }
              return 0;
            });
          } else {
            List<Future> sub = [];

            return new Directory(dir).list().listen((FileSystemEntity fse) {
              sub.add(_handleDir(fse.path));
            }).asFuture().then((_) {
              return Future.wait(sub).then((List<int> results) {
                int count = 0;
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
    Config config = new Config(settings,
        src: new Directory(srcDir),
        dst: dstDir == null ? null : new Directory(dstDir));

    return await deployConfig(config);
  }
  // int argIndex = 0;
  // Handle direct yaml file
  if (_argsResult.rest.length > 0) {
    String firstArg = _argsResult.rest[0];

    // First arg can specify a file and the default src directory
    if (firstArg.endsWith('.yaml')) {
      String yamlFileName = firstArg;
      String yamlFilePath = normalize(absolute(yamlFileName));
      srcDir = dirname(yamlFilePath);

      if (_argsResult.rest.length > 1) {
        srcDir = normalize(absolute(_argsResult.rest[1]));
        if (_argsResult.rest.length > 2) {
          dstDir = normalize(absolute(_argsResult.rest[2]));
        }
      }

      String content = await new File(yamlFilePath).readAsString();

      Map settings = loadYaml(content);
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
    String dir = _argsResult.rest.length == 0
        ? Directory.current.path
        : _argsResult.rest[0];

    srcDir = join(dir, 'build');
    dstDir = join(srcDir, 'deploy');

    _handleDir(srcDir).then((count) {
      if (count == 0) {
        print('no deploy.yaml file found in ${srcDir}');
      }
    });
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
  */
  return null;
}
