library tekartik.deploy.yaml;

import 'package:path/path.dart';
import 'dart:async';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:logging/logging.dart';
import 'package:yaml/yaml.dart';
import 'src/fs_deploy_impl.dart';

Logger _log = new Logger("tekartik.deploy");

///
/// Deploy between 2 folders with an option config file
///
/// [settings] can be set (files and exclude keys)
///
Future<int> fsDeploy(
    {Map settings, File yaml, Directory src, Directory dst}) async {
  if (settings == null) {
    if (yaml != null) {
      String content = await yaml.readAsString();
      settings = loadYaml(content);
    }
    settings ??= {};
  }

  // default src?
  src = getDeploySrc(yaml: yaml, src: src);

  Config config = new Config(settings, src: src, dst: dst);

  return await deployConfig(config);
}

///
/// Config format
///
/// files:
/// - file1
/// - file2
///
/// # default dest folder, compare to src
/// dst: ${src}/../deploy
class Config {
  // Either from the yaml file or specified
  FileSystemEntity _src;
  FileSystemEntity _dst;
  FileSystemEntity get dst => _dst;
  FileSystemEntity get src => _src;
  set src(FileSystemEntity src) {
    if (src != null) {
      _src = src;
      String dstBasename = basename(src.path);
      _dst = _src.fs.newLink(join(dirname(src.path), 'deploy', dstBasename));
    }
  }

  set dst(FileSystemEntity dst) {
    // don't replace with null
    if (dst != null) {
      _dst = dst;
    }
  }

//  Future _handleYaml(String dir, String yamlFilePath) {
//    return new File(yamlFilePath).readAsString().then((content) {
//
//      var doc = loadYaml(content);
//      if (doc is YamlMap) {
//        return _deploy(doc, relative(dir, from: srcDir)).then((_) {
//          return 1;
//        });
//      }
//      return 0;
//    });
//  }
//
//
//  Future deploy() {
//
//  }

  Map settings;
  Config(this.settings, {FileSystemEntity src, FileSystemEntity dst}) {
    if (src != null) {
      this.src = src;
    }
    if (dst != null) {
      this.dst = dst;
    }
    _init();
  }

  void _init() {
    if (settings != null) {
      var files = settings['files'];
      if (files is List) {
        for (var fileOrDir in files) {
          if (fileOrDir is String) {
            _entities.add(new EntityConfig(fileOrDir));
          } else if (fileOrDir is Map) {
            // - fileName: dstFileName
            String src = fileOrDir.keys.first;
            String dst = fileOrDir[src];

            _entities.add(new EntityConfig.withDst(src, dst));
          }
        }
      } else if (files is Map) {
        files.forEach((String key, var value) {
          //devPrint('$key => $value');
          _entities.add(new EntityConfig(key));
        });
      }

      // exclude
      this.exclude = settings['exclude'] as List<String>;
    }
  }

  List<EntityConfig> _entities = [];
  List<EntityConfig> get entities => _entities;

  List<String> exclude = [];

  @override
  String toString() {
    //return settings.toString() + "\n" +
    return _entities.toString();
  }
}

class EntityConfig {
  String _path;
  String _dst;
  String get src => _path;
  String get dst => (_dst == null) ? src : _dst;

  EntityConfig.withDst(this._path, this._dst);
  EntityConfig(this._path);

  bool get hasDst => _dst != null;
  @override
  String toString() {
    if (_dst == null) {
      return src;
    } else {
      return "$src => $dst";
    }
  }
}

Future<int> deployConfigEntity(Config config, String sub) async {
  TopCopy topCopy =
      new TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst));
  ChildCopy childCopy = new ChildCopy(topCopy, null, sub);
  return await childCopy.run();
}

Future<int> deployEntity(Config config, EntityConfig entityConfig) async {
  //String src = join(config.src.path, entityConfig.src);
  //String dst = join(config.dst.path, entityConfig.dst);
  if (entityConfig.hasDst) {
    _log.info("${entityConfig.src} => ${entityConfig.dst}");
  } else {
    _log.info("${entityConfig.src}");
  }
  //return _deployEntity(src, dst);
  // OLD

  TopCopy topCopy =
      new TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst));
  //ChildCopy child = new ChildCopy()
  return await topCopy.runChild(null,
      basename(entityConfig.src), basename(entityConfig.dst));
  /*  return await copyFileSystemEntity(
      config.src.fs.newLink(src), config.src.fs.newLink(dst));
      */
}

Future<int> deployConfig(Config config) async {
  Directory dst = config.dst.fs.newDirectory(config.dst.path);
  try {
    await dst.delete(recursive: true);
  } catch (_) {}
  await dst.create(recursive: true);

  //List<Future> futures = [];
  _log.info(config.entities);

  int sum = 0;
  if (config.entities.isEmpty) {
    // default copy all
    // recursiveLinkOrCopyNewerOptions);

    CopyOptions options = new CopyOptions(
        recursive: true,
        checkSizeAndModifiedDate: true,
        tryToLinkFile: true,
        exclude: config.exclude);

    TopCopy topCopy = new TopCopy(
        fsTopEntity(config.src), fsTopEntity(config.dst),
        options: options);
    sum += await topCopy.run();
  } else {
    CopyOptions options = new CopyOptions(
        recursive: true,
        checkSizeAndModifiedDate: true,
        tryToLinkFile: true,
        exclude: config.exclude);

    TopCopy topCopy = new TopCopy(
        fsTopEntity(config.src), fsTopEntity(config.dst),
        options: options);
    for (EntityConfig entityConfig in config.entities) {
      sum += await topCopy.runChild(null, entityConfig.src, entityConfig.dst);
    }
  }
  return sum;
}
