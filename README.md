# tekartik_deploy

Packaging and upload steps of a build: `fsDeploy` copies the files listed in a
`deploy.yaml` (or an inline map) from a build folder to a clean deploy folder,
then the deploy folder can be uploaded to Google Cloud Storage (`gsutil`) or to
an ftp/sftp host (`lftp`). Command line tools wrap the same functions.

Dart VM only (`dart:io`): build scripts, `tool/`, CI on Linux, macOS and
Windows. Nothing here works on the web or in a Flutter app.

## Getting started

The package is not on pub.dev, add it as a git dependency (usually a dev
dependency of the package whose tool scripts deploy):

```yaml
dev_dependencies:
  tekartik_deploy:
    git:
      url: https://github.com/tekartik/deploy.dart
```

Copy what ships from `build/web` to `build/deploy`:

```dart
import 'dart:io';

import 'package:tekartik_deploy/fs_deploy.dart';

Future<void> main() async {
  // build/deploy is deleted first, then filled with the listed entries.
  var count = await fsDeploy(
    src: Directory('build/web'),
    dst: Directory('build/deploy'),
    // Real copies instead of symbolic links (the folder is uploaded next).
    options: fsDeployOptionsNoSymLink,
    settings: {
      'files': ['index.html', 'main.dart.{js,mjs,wasm}', 'assets'],
      'optional': ['favicon.png'],
      'exclude': ['*.map'],
    },
  );
  stdout.writeln('$count file(s) deployed');
}
```

A runnable version (on a temporary folder) is in
[example/main.dart](example/main.dart).

## deploy.yaml

The same keys work in a `deploy.yaml` (`fsDeploy(yaml: File(...))`, its folder
is then the default source) or in the `settings` map:

```yaml
files:                     # required entries, relative to the source
  - index.html
  - assets/                # a directory, copied recursively
  - favicon.png: favicon.ico   # renamed
  - main.dart.{js,mjs,wasm}    # pattern (*, ?, {a,b}), must match at least one
optional:                  # skipped when missing, patterns can match nothing
  - flutter_service_worker.js
  - icons/
exclude:                   # globs removed from the copy
  - '*.map'
```

* Without `files:` (or with an empty list) the whole source folder is copied.
* Wildcards do not match a leading `.`, a pattern cannot be renamed.
* Quote the entries starting with `*` or `{` in yaml.

## Which API

| Need | Use | Import |
|---|---|---|
| copy a build to a deploy folder | `fsDeploy`, `fsDeployListFiles` (dry run) | `fs_deploy.dart` (`dart:io` types) |
| the same on any `fs_shim` file system (memory in tests) | `fsDeploy`, `Config`, `deployConfig` | `fs/fs_deploy.dart` |
| upload one file to Cloud Storage with its content type | `gsCopyFile` | `gs_deploy.dart` |
| sync a folder to Cloud Storage | `gsDeployCmd` (run it with `runCmd`) | `gs_deploy.dart` |
| upload a static web site, gzipped | `gsWebDeploy` | `gs_deploy.dart` |
| mirror a folder to an ftp/sftp host | `FtpClient().lftpDeploy` | `ftp_deploy.dart` |

`gsutil` must be in the `PATH` (or `TEKARTIK_GOOGLE_CLOUD_SDK_DIR` must point
to the Cloud SDK) and authenticated; `lftp` must be in the `PATH` for
`FtpClient`. The package passes no Google credentials.

## Command line tools

Run them from a package that depends on `tekartik_deploy`
(`dart run tekartik_deploy:fsdeploy ...`), or activate the package globally
(the package declares no `executables:`, so run them through `pub global run`):

```sh
dart pub global activate -s git https://github.com/tekartik/deploy.dart
dart pub global run tekartik_deploy:fsdeploy --help
```

* `fsdeploy`: from the current folder, finds the folders holding a
  `deploy.yaml` and deploys each `<path>` to `deploy/<path>` (then tries
  `build/`, into `build/deploy/`). The `files:` are linked (symbolic links)
  on Linux and macOS, copied on Windows.
* `fsdeploy <folder> <dst_folder>`: same search, into `<dst_folder>/<path>`.
* `fsdeploy <deploy.yaml> [<src_folder> [<dst_folder>]]`: one configuration,
  real copies, `dst_folder` defaulting to `<src>/../deploy/<src name>`.
* `fsdeploy --dir <src_folder> [<dst_folder>]`: the whole folder, no
  `deploy.yaml` needed.
* `gsdeploy <local_folder> gs://bucket/path`: `gsutil -m rsync -r`, exits with
  gsutil's exit code when it fails.
* `gswebdeploy <local_folder> gs://bucket/path`: the gzipped web deploy of
  `gsWebDeploy`, fails when an rsync fails.
* `gsdeploy --check` / `gswebdeploy --check`: exit code 0 if `gsutil` is found.
* `aedeploy` (App Engine) is obsolete and does nothing.

## Common pitfalls

* `fsDeploy` deletes the destination recursively before copying: give it a
  dedicated folder, never a folder holding the source or anything to keep.
* By default files are symbolic links to the source: pass
  `fsDeployOptionsNoSymLink` when the folder is uploaded, zipped or kept
  after the next build.
* `gsWebDeploy` builds its staging folders next to the source
  (`<parent>/gs/<name>/gzip` and `.../none`) and keeps them; it throws a
  `StateError` when an rsync fails (the next one is not run).
* `runCmd` (process_run) does not throw on a failed command: check
  `result.exitCode` when you run `gsDeployCmd` yourself.
* `gsutil rsync` here never deletes remote files; `lftpDeploy` mirrors with
  `--delete`, remote files absent from the source are deleted.
* `lftp` receives the user and password on its command line (percent encoded,
  but visible in the process list): keep them out of logs and of git (for
  example a `.local/ftp.yaml` read with `FtpClient().fromMap`).
* Links to directories are followed, except a link to one of the folders being
  copied or scanned (a link loop), which is skipped with a message on stderr.

Agent skills: [skills/tekartik-deploy-fs](skills/tekartik-deploy-fs/SKILL.md)
(local deploy, `deploy.yaml`, `fsdeploy`) and
[skills/tekartik-deploy-cloud](skills/tekartik-deploy-cloud/SKILL.md) (Cloud
Storage, ftp).
