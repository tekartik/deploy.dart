import 'package:fs_shim/fs_io.dart' as fs;
import 'package:tekartik_io_utils/io_utils_import.dart';

import 'fs/fs_deploy.dart' as fs;

export 'fs/fs_deploy.dart' show FsDeployOptions, fsDeployOptionsNoSymLink;

/// Copies the entries of [src] listed in [settings] (or in the [yaml]
/// `deploy.yaml` file) to [dst], and returns the number of files deployed.
///
/// [dst] is deleted first, then filled: never point it at a folder holding
/// [src]. It defaults to `<src>/../deploy/<src name>`; [src] defaults to the
/// folder of [yaml]. [settings] (the `files`, `optional` and `exclude` keys of
/// a `deploy.yaml`) wins over [yaml]. Without `files`, the whole [src] folder
/// is copied.
///
/// Files are symbolic links to the source unless [options] is
/// [fsDeployOptionsNoSymLink] (real copies).
Future<int> fsDeploy({
  fs.FsDeployOptions? options,
  Map? settings,
  File? yaml,
  Directory? src,
  Directory? dst,
}) {
  fs.File? fsYaml;
  fs.Directory? fsSrc;
  fs.Directory? fsDst;
  if (yaml != null) {
    fsYaml = fs.wrapIoFile(yaml);
  }
  if (src != null) {
    fsSrc = fs.wrapIoDirectory(src);
  }
  if (dst != null) {
    fsDst = fs.wrapIoDirectory(dst);
  }
  return fs.fsDeploy(
    options: options,
    settings: settings,
    yaml: fsYaml,
    src: fsSrc,
    dst: fsDst,
  );
}

/// The source files [fsDeploy] would deploy with the same [settings], [yaml]
/// and [src], nothing is written (a dry run).
Future<List<File>> fsDeployListFiles({
  Map? settings,
  File? yaml,
  Directory? src,
}) async {
  fs.File? fsYaml;
  fs.Directory? fsSrc;
  if (yaml != null) {
    fsYaml = fs.wrapIoFile(yaml);
  }
  if (src != null) {
    fsSrc = fs.wrapIoDirectory(src);
  }
  var fsFiles = await fs.fsDeployListFiles(
    settings: settings,
    yaml: fsYaml,
    src: fsSrc,
  );
  return List.generate(fsFiles.length, (int index) {
    return fs.unwrapIoFile(fsFiles[index]);
  });
}
