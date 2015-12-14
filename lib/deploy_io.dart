library tekartik.deploy.yaml;

import 'package:path/path.dart';
import 'dart:async';
import 'dart:io';
import 'package:tekartik_deploy/src/file_utils.dart';
import 'package:logging/logging.dart';

Logger _log = new Logger("tekartik.deploy");

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
  String _src;
  String _dst;
  String get dst => _dst;
  String get src => _src;
  set src(String src) {
    _src = src;
    String dstBasename = basename(src);
    _dst = join(dirname(src), 'deploy', dstBasename);
  }

  set dst(String dst) {
    _dst = dst;
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
  Config(this.settings, {String src, String dst}) {
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
    }
  }

  List<EntityConfig> _entities = [];
  List<EntityConfig> get entities => _entities;

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

Future<int> deployEntity(Config config, EntityConfig entityConfig) {
  String src = join(config.src, entityConfig.src);
  String dst = join(config.dst, entityConfig.dst);
  if (entityConfig.hasDst) {
    _log.info("${entityConfig.src} => ${entityConfig.dst}");
  } else {
    _log.info("${entityConfig.src}");
  }
  return _deployEntity(src, dst);
}

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

Future deployConfig(Config config) {
  emptyOrCreateDirSync(config.dst);

  List<Future> futures = [];
  _log.info(config.entities);
  if (config.entities.isEmpty) {
    List<FileSystemEntity> list =
        new Directory(config.src).listSync(recursive: false, followLinks: true);
    list.forEach((FileSystemEntity fse) {
      config.entities.add(new EntityConfig(basename(fse.path)));
    });
  }
  config.entities.forEach((EntityConfig entityConfig) {
    futures.add(deployEntity(config, entityConfig));
  });
//      for (String fileOrDir in settings['files']) {
//        print(fileOrDir);
//      }
  return Future.wait(futures).then((List<int> counts) {
    int sum = 0;
    counts.forEach((int count) => sum += count);
    return sum;
  });
}
