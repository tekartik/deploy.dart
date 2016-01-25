import 'package:fs_shim/fs.dart';

Directory getDeploySrc({File yaml, Directory src}) {
  // default src?
  if (src == null) {
    if (yaml == null) {
      throw new ArgumentError("need src or yaml specified");
    }
    src = yaml.parent;
  }
  return src.absolute;
}
