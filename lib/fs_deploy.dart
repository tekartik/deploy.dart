import 'package:fs_shim/fs_io.dart' as fs;
import 'package:tekartik_io_utils/io_utils_import.dart';

import 'fs/fs_deploy.dart' as fs;

export 'fs/fs_deploy.dart' show FsDeployOptions, fsDeployOptionsNoSymLink;

///
/// Deploy between 2 folders with an option config file
///
/// [settings] can be set (files and exclude keys)
///
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

///
/// Deploy list files
///
/// [settings] can be set (files and exclude keys)
///
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
