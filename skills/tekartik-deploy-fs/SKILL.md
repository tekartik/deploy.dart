---
name: tekartik-deploy-fs
description: >-
  Use when copying a build output to a deploy folder with tekartik_deploy:
  fsDeploy, fsDeployListFiles, FsDeployOptions, fsDeployOptionsNoSymLink, the
  deploy.yaml files/exclude format, the lower level Config / EntityConfig /
  deployConfig / deployConfigListFiles API, the dart:io
  (package:tekartik_deploy/fs_deploy.dart) versus fs_shim
  (package:tekartik_deploy/fs/fs_deploy.dart) libraries, and the fsdeploy
  command line tool.
---

# Local file deployment (tekartik_deploy)

`fsDeploy` copies a source directory to a destination directory, filtered by a
`files`/`exclude` configuration given inline or read from a `deploy.yaml`. It is
the packaging step of a build: pick what ships, drop the rest, hard-link when
possible. Remote (Google Storage, ftp) deployment lives in the same package but
in other libraries: see the `tekartik-deploy-cloud` skill.

## Guidelines

* Dependency (git, not on pub.dev; single package repo, so no `path:`):
  ```yaml
  dependencies:
    tekartik_deploy:
      git:
        url: https://github.com/tekartik/deploy.dart
  ```
  Use `dev_dependencies` when only a build/tool script needs it.
* Two libraries, same function names:
  * `package:tekartik_deploy/fs_deploy.dart` — takes `dart:io` `Directory` /
    `File`, returns `dart:io` `File`s. Use it in scripts and `tool/`.
  * `package:tekartik_deploy/fs/fs_deploy.dart` — takes `fs_shim`
    `Directory` / `File`, so the same code runs on a memory file system in
    tests. It also exposes the lower level `Config`, `EntityConfig`,
    `deployConfig`, `deployConfigEntity`, `deployEntity`,
    `deployConfigListFiles`.
  Both export `FsDeployOptions` and `fsDeployOptionsNoSymLink`. Do not import
  `package:tekartik_deploy/src/...`.
* `Future<int> fsDeploy({options, settings, yaml, src, dst})` returns the
  number of deployed files. `src` or `yaml` is mandatory (`ArgumentError`
  otherwise); with `yaml` alone, `src` is the yaml file's parent directory.
  `settings` wins over `yaml`, which is only read when `settings` is null.
* **`fsDeploy` deletes `dst` recursively before copying.** Point it at a
  dedicated folder (`build/deploy`, `deploy/web`), never at a directory holding
  anything you want to keep. Without `dst` the destination is
  `<src>/../deploy/<basename(src)>`.
* Configuration keys (inline `settings` map or `deploy.yaml`):
  * `files:` a list of file or directory names relative to `src`; an entry can
    be a single-entry map `- src_name: dst_name` to rename. Directories are
    copied recursively. When `files` is absent or empty, the whole `src`
    directory is copied.
  * `exclude:` a list of globs applied to the copy
    (`fs_shim`'s `CopyOptions.exclude`), e.g. `- '*.map'`.
  * Beware: the map form (`files:` followed by `name:` entries) keeps the keys
    but **ignores the destination values**; use the list-of-maps form to
    rename.
* Files are hard-linked when the file system allows it
  (`tryToLinkFile: true`) and skipped when size and modified date match. Pass
  `options: fsDeployOptionsNoSymLink` (same as
  `FsDeployOptions()..noSymLink = true`) to force real copies, which is what
  you want when the deploy folder is then zipped, uploaded or published.
* `Future<List<File>> fsDeployListFiles({settings, yaml, src})` applies the
  same filtering and returns the source files without writing anything: use it
  to check a configuration, or to feed another tool.
* Progress is logged through `package:logging` on the `tekartik.deploy` logger
  (plus a few prints); enable a logging handler if you want the per-entity
  lines.
* Command line (`dart pub global activate -s git https://github.com/tekartik/deploy.dart`
  installs `fsdeploy`, `gsdeploy`, `gswebdeploy`, `aedeploy`):
  * `fsdeploy` — scans the current directory (then `build/`) for directories
    containing a `deploy.yaml` and deploys each to `<src>/deploy`;
  * `fsdeploy <src_dir> <dst_dir>` — same scan, explicit destination;
  * `fsdeploy <deploy.yaml> [<src_dir> [<dst_dir>]]` — one configuration file;
  * `fsdeploy --dir <src_dir> [<dst_dir>]` — deploy a directory as is, no
    `deploy.yaml` needed;
  * `fsdeploy --version`, `fsdeploy -h`.
* `aedeploy` (App Engine) is a leftover: `lib/ae_deploy.dart` is entirely
  commented out and the executable does nothing useful. Ignore it.

## Examples

### deploy.yaml next to the build output

```yaml
files:
  - index.html
  - main.dart.js
  - assets
  - favicon.png: favicon.ico
exclude:
  - '*.map'
```

### Deploy a build folder from a tool script (dart:io)

```dart
import 'dart:io';

import 'package:tekartik_deploy/fs_deploy.dart';

Future<void> main() async {
  var count = await fsDeploy(
    src: Directory('build/web'),
    dst: Directory('build/deploy'),
    // Real copies, the folder is meant to be uploaded.
    options: fsDeployOptionsNoSymLink,
    settings: {
      'files': ['index.html', 'main.dart.js', 'assets'],
      'exclude': ['*.map'],
    },
  );
  stdout.writeln('$count file(s) deployed');
}
```

### Read the configuration from a deploy.yaml

```dart
import 'dart:io';

import 'package:tekartik_deploy/fs_deploy.dart';

Future<void> main() async {
  var yaml = File('build/web/deploy.yaml');
  // src defaults to the yaml parent (build/web),
  // dst defaults to build/deploy/web when omitted.
  var count = await fsDeploy(yaml: yaml, dst: Directory('build/deploy'));
  stdout.writeln('$count file(s) deployed');

  // Dry run: what would be deployed.
  for (var file in await fsDeployListFiles(yaml: yaml)) {
    stdout.writeln(file.path);
  }
}
```

### Same code on a memory file system (tests)

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:test/test.dart';

void main() {
  test('fs_deploy', () async {
    var fs = newFileSystemMemory();
    var src = fs.directory('/src');
    await src.create(recursive: true);
    await fs.file('/src/index.html').writeAsString('<html></html>');
    await fs.file('/src/index.html.map').writeAsString('{}');

    var count = await fsDeploy(
      src: src,
      dst: fs.directory('/dst'),
      settings: {
        'exclude': ['*.map'],
      },
    );
    expect(count, 1);
    expect(await fs.file('/dst/index.html').exists(), isTrue);
  });
}
```

### Lower level: build the config yourself

```dart
import 'package:fs_shim/fs_memory.dart';
import 'package:tekartik_deploy/fs/fs_deploy.dart';

Future<void> main() async {
  var fs = newFileSystemMemory();
  var config = Config({
    'files': [
      'index.html',
      {'favicon.png': 'favicon.ico'},
    ],
  }, src: fs.directory('/src'), dst: fs.directory('/dst'));

  for (var entity in config.entities) {
    print('${entity.src} => ${entity.dst} (renamed: ${entity.hasDst})');
  }
  print(await deployConfigListFiles(config));
  print(await deployConfig(config)); // no symlink
}
```

## Common mistakes

* Passing an existing shared folder as `dst`: it is deleted recursively first.
* Expecting `fsDeploy` to merge into `dst`: it always starts from a clean
  destination.
* Relying on the `files:` map form to rename files (values are ignored); use
  `- src: dst` list entries.
* Uploading a deploy folder made of hard links without
  `fsDeployOptionsNoSymLink`.
* Mixing the two libraries in one file: `fs_deploy.dart` and
  `fs/fs_deploy.dart` both define `fsDeploy` on different `Directory` types.
