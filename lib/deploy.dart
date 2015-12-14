library tekartik.deploy.yaml;

import 'package:path/path.dart';
import 'dart:async';
import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
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
  FileSystemEntity _src;
  FileSystemEntity _dst;
  FileSystemEntity get dst => _dst;
  FileSystemEntity get src => _src;
  set src(FileSystemEntity src) {
    _src = src;
    String dstBasename = basename(src.path);
    _dst = _src.fs.newLink(join(dirname(src.path), 'deploy', dstBasename));
  }

  set dst(FileSystemEntity dst) {
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
      this.exclude = settings['exclude'];
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

Future<int> deployEntity(Config config, EntityConfig entityConfig) async {
  String src = join(config.src.path, entityConfig.src);
  String dst = join(config.dst.path, entityConfig.dst);
  if (entityConfig.hasDst) {
    _log.info("${entityConfig.src} => ${entityConfig.dst}");
  } else {
    _log.info("${entityConfig.src}");
  }
  //return _deployEntity(src, dst);

  return await copyFileSystemEntity(
      config.src.fs.newLink(src), config.src.fs.newLink(dst));
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

    CopyOptions options =  new CopyOptions(
        recursive: true, checkSizeAndModifiedDate: true, tryToLinkFile: true,exclude: config.exclude);

    sum += await copyFileSystemEntity(config.src, config.dst,
        options: options);
    /*
    List<FileSystemEntity> list =
        new Directory(config.src).listSync(recursive: false, followLinks: true);
    list.forEach((FileSystemEntity fse) {
      config.entities.add(new EntityConfig(basename(fse.path)));
    });
    */
  }
  for (EntityConfig entityConfig in config.entities) {
    sum += await deployEntity(config, entityConfig);
  }
//      for (String fileOrDir in settings['files']) {
//        print(fileOrDir);
//      }
  return sum;
}
