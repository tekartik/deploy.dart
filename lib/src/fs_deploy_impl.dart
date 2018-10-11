import 'package:fs_shim/fs.dart';
import '../fs/fs_deploy.dart';
import 'package:tekartik_common_utils/common_utils_import.dart';
import 'package:fs_shim/utils/copy.dart';

class FsDeployImpl {
  FsDeployOptions options;

  FsDeployImpl(this.options);

  Future<int> deployConfig(Config config) async {
    Directory dst = config.dst.fs.newDirectory(config.dst.path);
    try {
      await dst.delete(recursive: true);
    } catch (_) {}
    await dst.create(recursive: true);

    //devPrint(config.entities);

    bool tryToLinkFile = !(this.options?.noSymLink == true);

    int sum = 0;

    CopyOptions copyOptions = CopyOptions(
        recursive: true,
        checkSizeAndModifiedDate: true,
        tryToLinkFile: tryToLinkFile,
        exclude: config.exclude);

    if (config.entities.isEmpty) {
      // default copy all
      // recursiveLinkOrCopyNewerOptions);
      TopCopy topCopy = TopCopy(
          fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      sum += await topCopy.run();
    } else {
      TopCopy topCopy = TopCopy(
          fsTopEntity(config.src), fsTopEntity(config.dst),
          options: copyOptions);
      for (EntityConfig entityConfig in config.entities) {
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
      throw ArgumentError("need src or yaml specified");
    }
    src = yaml.parent;
  }
  return src.absolute;
}
