import 'package:fs_shim/fs_io.dart';
import 'dart:async';
import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:yaml/yaml.dart';
import 'package:tekartik_deploy/src/file_utils.dart';
import 'package:tekartik_deploy/src/bin_version.dart';
//import 'package:tekartik_core/log_utils.dart';
//import 'package:tekartik_deploy/deploy_io.dart' hide Config, deployConfig;
import 'package:tekartik_deploy/fs/fs_deploy.dart';

const String _HELP = 'help';

Future _deployEntity(String src, String dst) {
  return FileSystemEntity.isDirectory(src).then((bool isDir) {
    if (isDir) {
      //fu.copyFilesIfNewer(src_, dst_);
      //return fu.linkDir(src_, dst_);
      return linkOrCopyFilesInDirIfNewer(src, dst, recursive: true);
    } else {
      return FileSystemEntity.isFile(src).then((bool isFile) {
        if (isFile) {
          return linkOrCopyFileIfNewer(src, dst);
        } else {
          throw "${src} entity not found";
        }
      });
    }
  });
}

String get currentScriptName => basenameWithoutExtension(Platform.script.path);

Future main(List<String> arguments) async {
  //debugQuickLogging(Level.FINE);

  ArgParser parser = new ArgParser(allowTrailingOptions: true);
  parser.addFlag(_HELP, abbr: 'h', help: 'Usage help', negatable: false);
  parser.addFlag("dir",
      abbr: 'd',
      help: 'Deploy a directory as is, even if no deploy.yaml is present',
      negatable: false);
  parser.addFlag("version",
      help: 'Display the script version', negatable: false);

  ArgResults _argsResult = parser.parse(arguments);

  _usage() {
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

  var help = _argsResult[_HELP] as bool;
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

  var dirOnly = _argsResult["dir"] as bool;

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

  Future<int> _handleDir(String dir) async {
    // this is a directoru
    String deployYaml = "deploy.yaml";

    return await (FileSystemEntity.isDirectory(dir)).then((bool isDir) {
      //print("dir $dir: ${isDir}");
      if (isDir) {
        String deployYamlPath = join(dir, deployYaml);
        //devPrint(dir);
        return FileSystemEntity.isFile(deployYamlPath)
            .then((bool containsDeployYaml) async {
          //print("gitFile $gitFile: ${containsDotGit}");
          if (containsDeployYaml) {
            //gitPull(dir);
            return await new File(deployYamlPath)
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
            List<Future<int>> sub = [];

            return new Directory(dir)
                .list()
                .listen((FileSystemEntity fse) {
                  sub.add(_handleDir(fse.path));
                })
                .asFuture()
                .then((_) {
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
    if (firstArg.endsWith(".yaml")) {
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
    String dir = _argsResult.rest.length == 0
        ? Directory.current.path
        : _argsResult.rest[0];

    // try root
    srcDir = dir;
    dstDir = join(srcDir, 'deploy');
    int count = await _handleDir(srcDir);

    if (count == 0) {
      print('no deploy.yaml file found in ${srcDir}');
      srcDir = join(dir, 'build');
      dstDir = join(srcDir, 'deploy');

      // check where build exists first
      if (await new Directory(srcDir).exists()) {
        int count = await _handleDir(srcDir);
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
//    if (firstArg.endsWith(".yaml")) {
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
