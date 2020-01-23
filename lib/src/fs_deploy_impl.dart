import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'package:tekartik_deploy/fs/fs_deploy.dart';

class FsDeployImpl {
  FsDeployOptions options;

  FsDeployImpl(this.options);

  Future<int> deployConfig(Config config) async {
    try {
      final dst = config.dst.fs.directory(config.dst.path);
      final src = config.src.fs.directory(config.src.path);
      try {
        await dst.delete(recursive: true);
      } catch (_) {}
      await dst.create(recursive: true);

      //devPrint(config.entities);

      final tryToLinkFile = !(options?.noSymLink == true);

      var sum = 0;

      final copyOptions = CopyOptions(
          recursive: true,
          checkSizeAndModifiedDate: true,
          tryToLinkFile: tryToLinkFile,
          exclude: config.exclude);

      if (config.entities.isEmpty) {
        var files = await copyDirectoryListFiles(src, options: copyOptions);

        // default copy all
        // recursiveLinkOrCopyNewerOptions);
        /*
      final topCopy = TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      sum += await topCopy.run();
      */
        await copyDirectory(src, dst, options: copyOptions);

        return files.length;
      } else {
        /*
      final topCopy = TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      for (final entityConfig in config.entities) {
        sum += await topCopy.runChild(null, entityConfig.src, entityConfig.dst);
      }
       */
        for (final entityConfig in config.entities) {
          var srcPath = src.fs.path.join(src.path, entityConfig.src);
          var dstPath = dst.fs.path.join(dst.path, entityConfig.dst);
          var isDir = await src.fs.isDirectory(srcPath);
          if (isDir) {
            var srcDir = src.fs.directory(srcPath);
            var dstDir = dst.fs.directory(dstPath);
            var files =
                await copyDirectoryListFiles(srcDir, options: copyOptions);
            sum += files.length;
            await copyDirectory(srcDir, dstDir, options: copyOptions);
          } else {
            await copyFile(src.fs.file(srcPath), dst.fs.file(dstPath),
                options: copyOptions);
            sum += 1;
          }

          //  sum += await topCopy.runChild(null, entityConfig.src, entityConfig.dst);
        }
      }
      return sum;
    } catch (e) {
      print('deployConfig $e');
      rethrow;
    }
  }
}

Directory getDeploySrc({File yaml, Directory src}) {
  // default src?
  if (src == null) {
    if (yaml == null) {
      throw ArgumentError('need src or yaml specified');
    }
    src = yaml.parent;
  }
  return src.absolute;
}

abstract class ConfigInternal implements Config {
  List<EntityConfig> get entityConfigs;
}

mixin ConfigMixin implements ConfigInternal {
  Map settings;
  @override
  List<String> exclude = [];
  final _entities = <EntityConfig>[];

  @override
  List<EntityConfig> get entities => _entities;

  void init({Map settings, FileSystemEntity src, FileSystemEntity dst}) {
    this.src = src;
    this.dst = dst;
    this.settings = settings;
    if (entityConfigs != null) {
      _entities.addAll(entityConfigs);
    } else if (settings != null) {
      var files = settings['files'];
      if (files is List) {
        for (var fileOrDir in files) {
          if (fileOrDir is String) {
            _entities.add(EntityConfig(fileOrDir));
          } else if (fileOrDir is Map) {
            // - fileName: dstFileName
            var src = fileOrDir.keys.first as String;
            var dst = fileOrDir[src] as String;

            _entities.add(EntityConfig.withDst(src, dst));
          }
        }
      } else if (files is Map) {
        files.forEach((var key, var value) {
          //devPrint('$key => $value');
          _entities.add(EntityConfig(key as String));
        });
      }

      // exclude
      exclude = (settings['exclude'] as List)?.cast<String>();
    }
  }
}

class ConfigImpl extends Config with ConfigMixin implements ConfigInternal {
  ConfigImpl(Map settings, {FileSystemEntity src, FileSystemEntity dst})
      : super.impl() {
    init(settings: settings, src: src, dst: dst);
  }

  @override
  List<EntityConfig> get entityConfigs => null;
}

class FsDeployConfig extends Config with ConfigMixin implements ConfigInternal {
  final List<EntityConfig> _inputEntities;
  FsDeployConfig(
      {List<EntityConfig> entities, FileSystemEntity src, FileSystemEntity dst})
      : _inputEntities = entities,
        super.impl() {
    init(src: src, dst: dst);
  }

  @override
  List<EntityConfig> get entityConfigs => _inputEntities;
}
