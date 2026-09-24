import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:fs_shim/utils/glob.dart';
import 'package:path/path.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import 'package:tekartik_deploy/fs/fs_deploy.dart';

/// Log message.
void _log(String message) {
  // ignore: avoid_print
  print('fs_deploy: $message');
}

/// FsDeploy implementation.
class FsDeployImpl {
  /// Options for fs deploy.
  FsDeployOptions? options;

  /// FsDeploy implementation.
  FsDeployImpl(this.options);

  /// Deploy a config.
  Future<int> deployConfig(Config config) async {
    try {
      final dst = config.dst!.fs.directory(config.dst!.path);
      final src = config.src!.fs.directory(config.src!.path);
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
        exclude: config.exclude,
      );

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
        for (final entityConfig in await resolveDeployEntities(
          src,
          config.entities,
        )) {
          var srcPath = src.fs.path.join(src.path, entityConfig.src);
          var dstPath = dst.fs.path.join(dst.path, entityConfig.dst);
          var isDir = await src.fs.isDirectory(srcPath);
          if (isDir) {
            var srcDir = src.fs.directory(srcPath);
            var dstDir = dst.fs.directory(dstPath);
            var files = await copyDirectoryListFiles(
              srcDir,
              options: copyOptions,
            );
            sum += files.length;
            await copyDirectory(srcDir, dstDir, options: copyOptions);
          } else {
            await copyFile(
              src.fs.file(srcPath),
              dst.fs.file(dstPath),
              options: copyOptions,
            );
            sum += 1;
          }

          //  sum += await topCopy.runChild(null, entityConfig.src, entityConfig.dst);
        }
      }
      return sum;
    } catch (e) {
      _log('deployConfig $e');
      rethrow;
    }
  }
}

/// True if [path] is a pattern (contains `*`, `?` or `{`).
bool deployPathIsPattern(String path) => path.contains(_patternRegExp);

final _patternRegExp = RegExp(r'[*?{]');

/// Expand `{a,b}` alternatives, i.e. `main.dart.{js,wasm}` gives
/// `main.dart.js` and `main.dart.wasm`. Nested and multiple groups are
/// supported, unbalanced braces are kept as is.
List<String> deployPathExpandBraces(String pattern) {
  var start = pattern.indexOf('{');
  if (start < 0) {
    return [pattern];
  }
  var depth = 0;
  var alternatives = <String>[];
  var alternativeStart = start + 1;
  for (var i = start + 1; i < pattern.length; i++) {
    var chr = pattern[i];
    if (chr == '{') {
      depth++;
    } else if (chr == '}') {
      if (depth == 0) {
        alternatives.add(pattern.substring(alternativeStart, i));
        var prefix = pattern.substring(0, start);
        var suffix = pattern.substring(i + 1);
        return {
          for (var alternative in alternatives)
            ...deployPathExpandBraces('$prefix$alternative$suffix'),
        }.toList();
      }
      depth--;
    } else if (chr == ',' && depth == 0) {
      alternatives.add(pattern.substring(alternativeStart, i));
      alternativeStart = i + 1;
    }
  }
  return [pattern];
}

/// Resolve [entities] against [src]: patterns are replaced by the matching
/// entities and missing optional entities are dropped.
///
/// Required plain entities are kept as is (copying them fails if missing),
/// a required pattern must match at least one entity.
Future<List<EntityConfig>> resolveDeployEntities(
  Directory src,
  List<EntityConfig> entities,
) async {
  var resolved = <EntityConfig>[];
  var keys = <String>{};
  void add(EntityConfig entity) {
    if (keys.add('${entity.src}\n${entity.dst}')) {
      resolved.add(entity);
    }
  }

  for (var entity in entities) {
    if (entity.isPattern) {
      if (entity.hasDst) {
        throw ArgumentError(
          'Pattern ${entity.src} cannot be renamed to ${entity.dst}',
        );
      }
      var paths = <String>[];
      for (var pattern in deployPathExpandBraces(entity.src)) {
        paths.addAll(await _patternPaths(src, pattern));
      }
      if (paths.isEmpty) {
        if (!entity.optional) {
          throw StateError('No match for ${entity.src} in ${src.path}');
        }
        _log('skipping ${entity.src}, no match');
      }
      for (var path in paths) {
        add(EntityConfig(path));
      }
    } else if (entity.optional) {
      if (await _exists(src, entity.src)) {
        add(entity);
      } else {
        _log('skipping ${entity.src}, not found');
      }
    } else {
      add(entity);
    }
  }
  return resolved;
}

String _join(Directory dir, String relativePath) =>
    dir.fs.path.joinAll([dir.path, ...posix.split(relativePath)]);

Future<bool> _exists(Directory dir, String relativePath) async =>
    await dir.fs.type(_join(dir, relativePath)) !=
    FileSystemEntityType.notFound;

/// Existing paths (relative to [src], posix) matching [pattern] (braces
/// already expanded), `*` and `?` only apply within a path segment.
Future<List<String>> _patternPaths(Directory src, String pattern) async {
  var fs = src.fs;
  var paths = <String>[''];
  for (var segment in posix.split(pattern)) {
    var matches = <String>[];
    for (var parent in paths) {
      if (!deployPathIsPattern(segment)) {
        matches.add(posix.join(parent, segment));
        continue;
      }
      var dirPath = _join(src, parent);
      if (!await fs.isDirectory(dirPath)) {
        continue;
      }
      var names = [
        await for (var entity in fs.directory(dirPath).list())
          fs.path.basename(entity.path),
      ]..sort();
      for (var name in names) {
        // Like shells, wildcards do not match a leading dot.
        if (name.startsWith('.') && !segment.startsWith('.')) {
          continue;
        }
        if (Glob.matchPart(segment, name)) {
          matches.add(posix.join(parent, name));
        }
      }
    }
    paths = matches;
  }
  return [
    for (var path in paths)
      if (await _exists(src, path)) path,
  ];
}

/// Get deploy source directory.
Directory getDeploySrc({File? yaml, Directory? src}) {
  // default src?
  if (src == null) {
    if (yaml == null) {
      throw ArgumentError('need src or yaml specified');
    }
    src = yaml.parent;
  }
  return src.absolute;
}

/// Config internal interface.
abstract class ConfigInternal implements Config {
  /// Entity configs.
  List<EntityConfig>? get entityConfigs;
}

/// Config mixin.
mixin ConfigMixin implements ConfigInternal {
  /// Settings.
  Map? settings;
  @override
  /// Exclude patterns.
  List<String>? exclude = [];
  final _entities = <EntityConfig>[];

  @override
  /// Entities.
  List<EntityConfig> get entities => _entities;

  /// Initialize the config.
  void init({Map? settings, FileSystemEntity? src, FileSystemEntity? dst}) {
    this.src = src;
    this.dst = dst;
    this.settings = settings;
    if (entityConfigs != null) {
      _entities.addAll(entityConfigs!);
    } else if (settings != null) {
      void addEntities(Object? files, {required bool optional}) {
        if (files is List) {
          for (var fileOrDir in files) {
            if (fileOrDir is String) {
              _entities.add(EntityConfig(fileOrDir, optional: optional));
            } else if (fileOrDir is Map) {
              // - fileName: dstFileName
              var src = fileOrDir.keys.first as String;
              var dst = fileOrDir[src] as String?;

              _entities.add(EntityConfig.withDst(src, dst, optional: optional));
            }
          }
        } else if (files is Map) {
          files.forEach((var key, var value) {
            //devPrint('$key => $value');
            _entities.add(EntityConfig(key as String, optional: optional));
          });
        }
      }

      addEntities(settings['files'], optional: false);
      // skipped when missing
      addEntities(settings['optional'], optional: true);

      // exclude
      exclude = (settings['exclude'] as List?)?.cast<String>();
    }
  }
}

/// Config implementation.
class ConfigImpl extends Config with ConfigMixin implements ConfigInternal {
  /// Config implementation.
  ConfigImpl(Map? settings, {FileSystemEntity? src, FileSystemEntity? dst})
    : super.impl() {
    init(settings: settings, src: src, dst: dst);
  }

  @override
  /// Entity configs.
  List<EntityConfig>? get entityConfigs => null;
}

/// FsDeploy config.
class FsDeployConfig extends Config with ConfigMixin implements ConfigInternal {
  final List<EntityConfig>? _inputEntities;

  /// FsDeploy config.
  FsDeployConfig({
    List<EntityConfig>? entities,
    FileSystemEntity? src,
    FileSystemEntity? dst,
  }) : _inputEntities = entities,
       super.impl() {
    init(src: src, dst: dst);
  }

  @override
  /// Entity configs.
  List<EntityConfig>? get entityConfigs => _inputEntities;
}
