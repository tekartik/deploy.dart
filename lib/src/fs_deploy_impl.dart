import 'package:fs_shim/fs.dart';
import 'package:fs_shim/utils/copy.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';

import '../fs/fs_deploy.dart';

class FsDeployImpl {
  FsDeployOptions options;

  FsDeployImpl(this.options);

  Future<int> deployConfig(Config config) async {
    final dst = config.dst.fs.directory(config.dst.path);
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
      // default copy all
      // recursiveLinkOrCopyNewerOptions);
      final topCopy = TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      sum += await topCopy.run();
    } else {
      final topCopy = TopCopy(fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      for (final entityConfig in config.entities) {
        sum += await topCopy.runChild(null, entityConfig.src, entityConfig.dst);
      }
    }
    return sum;
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
