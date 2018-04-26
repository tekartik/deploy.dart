library tekartik_deploy.src.file_utils;

import 'dart:io';
import 'dart:async';
//import 'package:logging/logging.dart' as log;
import 'package:path/path.dart';

Future copyFile(String input, String output) {
  var inStream = new File(input).openRead();
  IOSink outSink;
  File outFile = new File(output);
  outSink = outFile.openWrite();
  return inStream.pipe(outSink).catchError((_) {
    Directory parent = outFile.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    outSink = outFile.openWrite();
    inStream = new File(input).openRead();
    return inStream.pipe(outSink);
  });
}

/**
 * Parameter are directory path
 */
Future<int> copyFilesIfNewer(String input, String output,
    {bool recursive: true, bool followLinks: false}) {
  int count = 0;
  Completer<int> completer = new Completer();
  List<Future> futures = new List();
  new Directory(input)
      .list(recursive: recursive, followLinks: followLinks)
      .listen((FileSystemEntity fse) {
    //print("# ${fse.path}");
    if (FileSystemEntity.isFileSync(fse.path)) {
      String relativePath = relative(fse.path, from: input);
      futures.add(copyFileIfNewer(fse.path, join(output, relativePath))
          .then((int copied) {
        count += copied;
      }));
    }
  }, onDone: () {
    Future.wait(futures).then((_) => completer.complete(count));
  });

  return completer.future;
}

Future<int> copyFileIfNewer(String input, String output) async {
  FileStat inputStat = await FileStat.stat(input);
  FileStat outputStat = await FileStat.stat(output);
  try {
    if ((inputStat.size != outputStat.size) ||
        (inputStat.modified.isAfter(outputStat.modified))) {
      await copyFile(input, output);
      return 1;
    } else {
      return 0;
    }
  } catch (e) {
    await copyFile(input, output);
    return 1;
  }

  /*
  return await FileStat.stat(input).then((FileStat inputStat) {
    return FileStat.stat(output).then((FileStat outputStat) {
      if ((inputStat.size != outputStat.size) ||
          (inputStat.modified.isAfter(outputStat.modified))) {
        return copyFile(input, output).then((_) {
          return 1;
        });
      } else {
        return 0;
      }
    }).catchError((e) {
      return copyFile(input, output).then((_) {
        return 1;
      });
    });
  });
  */
}

bool dirIsSymlink(Directory dir) {
  return FileSystemEntity.isLinkSync(dir.path);
}

void writeStringContentSync(String path, String content) {
  File file = new File(path);
  try {
    file.writeAsStringSync(content);
  } on FileSystemException {
    Directory parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    file.writeAsStringSync(content);
  }
}

Future _writeBytes(File file, List<int> bytes) {
  return file.writeAsBytes(bytes);
}

Future writeBytes(File file, List<int> bytes) {
  return _writeBytes(file, bytes).catchError((e) {
    Directory parent = file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    return _writeBytes(file, bytes);
  });
}

Directory emptyOrCreateDirSync(String path) {
  Directory dir = new Directory(path);
  if (dir.existsSync()) {
    dir.deleteSync(recursive: true);
  }
  dir.createSync(recursive: true);
  return dir;
}

Future<int> dirSize(String path) async {
  int size = 0;
  List<Future> futures = [];

  return await new Directory(path)
      .list(recursive: true, followLinks: true)
      .listen((FileSystemEntity fse) {
        //devPrint(FileSystemEntity.type(fse.path));
        futures.add(FileSystemEntity.isFile(fse.path).then((bool isFile) {
          if (isFile) {
            return fse.stat().then((FileStat stat) {
              //devPrint("${stat.size} ${fse}");
              size += stat.size;
            });
          }
        }));
      })
      .asFuture()
      .then((_) {
        return Future.wait(futures).then((_) {
          return size;
        });
      });
}

/**
 * link dir (work on all platforms)
 */

/**
 * Not for windows
 */
Future<int> linkFile(String target, String link) {
  if (Platform.isWindows) {
    throw "not supported on windows";
  }
  return _link(target, link);
}

/**
 * link dir (work on all platforms)
 */
Future<int> _link(String target, String link) async {
  link = normalize(absolute(link));
  target = normalize(absolute(target));
  Link ioLink = new Link(link);

  // resolve target
  if (FileSystemEntity.isLinkSync(target)) {
    target = new Link(target).targetSync();
  }

  if (FileSystemEntity.isLinkSync(target)) {
    target = new Link(target).targetSync();
  }

  String existingLink = null;
  if (ioLink.existsSync()) {
    existingLink = ioLink.targetSync();
    //print(ioLink.resolveSymbolicLinksSync());
    if (existingLink == target) {
      return new Future.value(0);
    } else {
      ioLink.deleteSync();
    }
  }

  return await ioLink.create(target).catchError((e) {
    Directory parent = new Directory(dirname(link));
    if (!parent.existsSync()) {
      try {
        parent.createSync(recursive: true);
      } catch (e) {
        // ignore the error
      }
    } else {
      // ignore the error and try again
      // print('linkDir failed($e) - target: $target, existingLink: $existingLink');
      // throw e;
    }
    return ioLink.create(target);
  }).then((_) => 1);
}

/**
 * link dir (work on all platforms)
 */
Future<int> linkDir(String target, String link) {
  // resolve target
  if (FileSystemEntity.isLinkSync(target)) {
    target = new Link(target).targetSync();
  }
  if (!FileSystemEntity.isDirectorySync(target)) {
    print('$target not a directory');
    return new Future.value(0);
  }
  return _link(target, link);
}

/**
 * on windows
 */
Future<int> linkOrCopyFileIfNewer(String input, String output) {
  //devPrint('cplnk $input -> $output');
  if (Platform.isWindows) {
    return copyFileIfNewer(input, output);
  } else {
    return linkFile(input, output);
  }
}

/**
 * create the dirs but copy or link the files
 */
Future<int> linkOrCopyFilesInDirIfNewer(String input, String output,
    {bool recursive: true, List<String> but}) async {
  List<Future<int>> futures = new List();

  List<FileSystemEntity> entities =
      new Directory(input).listSync(recursive: false, followLinks: true);
  new Directory(output).createSync(recursive: true);
  entities.forEach((entity) {
    bool ignore = false;
    if (but != null) {
      if (but.contains(basename(entity.path))) {
        ignore = true;
      }
    }

    if (!ignore) {
      if (FileSystemEntity.isFileSync(entity.path)) {
        String file = relative(entity.path, from: input);
        futures
            .add(linkOrCopyFileIfNewer(join(input, file), join(output, file)));
      } else if (FileSystemEntity.isDirectorySync(entity.path)) {
        if (recursive) {
          String dir = relative(entity.path, from: input);
          String outputDir = join(output, dir);

          futures.add(linkOrCopyFilesInDirIfNewer(join(input, dir), outputDir));
        }
      }
    }
  });

  return await Future.wait(futures).then((List<int> list) {
    int count = 0;
    list.forEach((delta) {
      count += delta;
    });
    return count;
  });
}

/**
 * Helper to copy recursively a source to a destination
 */
Future<int> linkOrCopyIfNewer(String src, String dst) async {
  return await FileSystemEntity.isDirectory(src).then((bool isDir) {
    if (isDir) {
      return linkOrCopyFilesInDirIfNewer(src, dst, recursive: true);
    } else {
      return FileSystemEntity.isFile(src).then((bool isFile) {
        if (isFile) {
          return linkOrCopyFileIfNewer(src, dst);
        } else {
          throw "${src} entity not found";
        }
      });
    }
  });
}

/**
 * Helper to copy recursively a source to a destination
 */
Future<int> deployEntitiesIfNewer(
    String srcDir, String dstDir, List<String> entitiesPath) async {
  List<Future> futures = [];
  for (String entityPath in entitiesPath) {
    futures.add(
        linkOrCopyIfNewer(join(srcDir, entityPath), join(dstDir, entityPath)));
  }
  return await Future.wait(futures).then((_) {
    // Todo
    return 0;
  });
}

/**
 * obsolete
 */
Future<int> createSymlink(
    Directory targetDir, Directory linkDir, String targetSubPath,
    [String linkSubPath]) async {
  if (linkSubPath == null) {
    linkSubPath = targetSubPath;
  }
  //linkDir.
  String target = join(targetDir.path, targetSubPath);
  String link = join(linkDir.path, linkSubPath);

  if (FileSystemEntity.typeSync(target) == FileSystemEntityType.NOT_FOUND) {
    print("$target not found from ${Directory.current}");
    return new Future.value(0);
  }

  if (FileSystemEntity.isDirectorySync(target)) {
    //if (!FileSystemEntity.isLinkSync(target)) {
    Directory inDir = new Directory(target);
    Directory outDir = new Directory(link);
    List<FileSystemEntity> list = inDir.listSync();
    List<Future<int>> futures = new List();
    for (FileSystemEntity entity in list) {
      //Path path = new Path(entity.path);
      //print(path);
      futures.add(createSymlink(inDir, outDir, basename(entity.path)));
    }
    return await Future.wait(futures).then((List<int> list) {
      //return list.last;
      return 0;
    });
    //} else
  } else {
    new Directory(normalize(absolute(dirname(link))))
        .createSync(recursive: true);
    //create parent if necessary
    //pathParent(link).createSync(recursive: true);

    // Windows has a special implementation that will copy the files
    if (Platform.isWindows) {
      await copyFile(target, link);
      return 1;
    } else {
      // print("${target} ${new Directory.fromPath(target).existsSync()}");
      Link ioLink = new Link(link);
      return await ioLink.create(absolute(target)).then((_) {
        return 0;
      }).catchError((_) {
        return 0;
      });
    }
  }
}
