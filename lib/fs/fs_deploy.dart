library;

import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:tekartik_common_utils/log_utils.dart';
import 'package:tekartik_deploy/src/fs_deploy_impl.dart';
import 'package:yaml/yaml.dart';

/// Logger for tekartik.deploy.
Logger _log = Logger('tekartik.deploy');

/// Options to prevent symlink creation.
FsDeployOptions fsDeployOptionsNoSymLink = FsDeployOptions()..noSymLink = true;

/// Options for fs deploy.
class FsDeployOptions {
  /// Do not use symlinks.
  bool? noSymLink;
}

/// Deploy between 2 folders with an option config file.
///
/// [settings] can be set (files and exclude keys)
///
Future<int> fsDeploy({
  FsDeployOptions? options,
  Map? settings,
  File? yaml,
  Directory? src,
  Directory? dst,
}) async {
  if (settings == null) {
    if (yaml != null) {
      final content = await yaml.readAsString();
      settings = loadYaml(content) as Map?;
    }
    settings ??= {};
  }

  // default src?
  src = getDeploySrc(yaml: yaml, src: src);

  final config = Config(settings, src: src, dst: dst);

  //return await deployConfig(config);
  return await FsDeployImpl(options).deployConfig(config);
}

/// List source files.
///
Future<List<File>> fsDeployListFiles({
  Map? settings,
  File? yaml,
  Directory? src,
}) async {
  if (settings == null) {
    if (yaml != null) {
      final content = await yaml.readAsString();
      settings = loadYaml(content) as Map?;
    }
    settings ??= {};
  }

  // default src?
  src = getDeploySrc(yaml: yaml, src: src);

  final config = Config(settings, src: src);

  return await deployConfigListFiles(config);
}

/// Config setting.
class ConfigSetting {
  /// Source path.
  String? src;
}

/// Config transform settings.
class ConfigTransformSettings {
  /// Destination path.
  String? dst;
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
abstract class Config {
  // Either from the yaml file or specified
  FileSystemEntity? _src;
  FileSystemEntity? _dst;

  /// Destination entity.
  FileSystemEntity? get dst => _dst;

  /// Source entity.
  FileSystemEntity? get src => _src;

  /// Set the source entity.
  set src(FileSystemEntity? src) {
    if (src != null) {
      _src = src;
      var fs = _src!.fs;
      final dstBasename = fs.path.basename(src.path);
      _dst = _src!.fs.link(
        fs.path.join(fs.path.dirname(src.path), 'deploy', dstBasename),
      );
    }
  }

  /// Set the destination entity.
  set dst(FileSystemEntity? dst) {
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

  /// Config implementation.
  Config.impl();

  /// Config factory.
  factory Config(
    Map? settings, {
    FileSystemEntity? src,
    FileSystemEntity? dst,
  }) => ConfigImpl(settings, src: src, dst: dst);

  /// Entities to deploy.
  List<EntityConfig> get entities;

  /// Exclude patterns.
  List<String>? get exclude;

  @override
  String toString() {
    //return settings.toString() + '\n' +
    return entities.toString();
  }
}

/// Entity config.
class EntityConfig {
  final String _path;
  String? _dst;

  /// Source path.
  String get src => _path;

  /// Destination path.
  String? get dst => (_dst == null) ? src : _dst;

  /// Entity config with destination.
  EntityConfig.withDst(this._path, this._dst);

  /// Entity config.
  EntityConfig(this._path);

  /// True if a destination is defined.
  bool get hasDst => _dst != null;

  @override
  String toString() {
    if (_dst == null) {
      return src;
    } else {
      return '$src => $dst';
    }
  }

  @override
  int get hashCode => src.hashCode;

  @override
  bool operator ==(other) {
    if (other is EntityConfig) {
      if (other.src != src) {
        return false;
      }
      if (other.dst != dst) {
        return false;
      }
      return true;
    }
    return false;
  }
}

/// Deploy config entity.
Future<int> deployConfigEntity(Config config, String sub) async {
  final topCopy = TopCopy(fsTopEntity(config.src!), fsTopEntity(config.dst!));

  /// Try to symlink first
  final childCopy = ChildCopy(topCopy, defaultCloneOptions, sub);
  return await childCopy.run();
}

/// Deploy entity.
Future<int> deployEntity(Config config, EntityConfig entityConfig) async {
  //String src = join(config.src.path, entityConfig.src);
  //String dst = join(config.dst.path, entityConfig.dst);
  if (entityConfig.hasDst) {
    _log.info('${entityConfig.src} => ${entityConfig.dst}');
  } else {
    _log.info(entityConfig.src);
  }
  //return _deployEntity(src, dst);
  // OLD

  final topCopy = TopCopy(fsTopEntity(config.src!), fsTopEntity(config.dst!));
  //ChildCopy child = new ChildCopy()
  return await topCopy.runChild(
    /// Try to symlink first
    defaultCloneOptions,
    basename(entityConfig.src),
    basename(entityConfig.dst!),
  );
  /*  return await copyFileSystemEntity(
      config.src.fs.newLink(src), config.src.fs.newLink(dst));
      */
}

/// Deploy config list files.
Future<List<File>> deployConfigListFiles(Config config) async {
  final files = <File>[];

  // if null include all
  List<String>? include;

  if (config.entities.isNotEmpty) {
    // default copy all
    // recursiveLinkOrCopyNewerOptions);
    include = <String>[];
    for (final entityConfig in config.entities) {
      include.add(entityConfig.src);
    }
  }

  final options = CopyOptions(
    recursive: true,
    checkSizeAndModifiedDate: true,
    tryToLinkFile: true,
    exclude: config.exclude,
    include: include,
  );

  files.addAll(
    await copyDirectoryListFiles(config.src as Directory, options: options),
  );

  return files;
}

/// FsDeploy stat entity.
class FsDeployStatEntity {
  /// Source path.
  String? src;

  /// Destination path.
  String? dst;
}

/// FsDeploy stat.
class FsDeployStat {
  /// Entities.
  List<FsDeployStatEntity>? entities;
}

/// Deploy config.
Future<int> deployConfig(Config config) async {
  return await FsDeployImpl(
    FsDeployOptions()..noSymLink = true,
  ).deployConfig(config);
}
