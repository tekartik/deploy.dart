import 'dart:async';
import 'dart:io';
import 'fs/fs_deploy.dart' as fs;
import 'package:fs_shim/fs_io.dart' as fs;
///
/// Deploy between 2 folders with an option config file
///
/// [settings] can be set (files and exclude keys)
///
Future<int> fsDeploy(
    {Map settings, File yaml, Directory src, Directory dst}) {
  fs.File fsYaml;
  fs.Directory fsSrc;
  fs.Directory fsDst;
  if (yaml != null) {
    fsYaml = fs.wrapIoFile(yaml);
  }
  if (src != null) {
    fsSrc = fs.wrapIoDirectory(src);
  }
  if (dst != null) {
    fsDst = fs.wrapIoDirectory(dst);
  }
  return fs.fsDeploy(settings: settings, yaml: fsYaml, src: fsSrc, dst:fsDst);
}