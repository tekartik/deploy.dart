---
name: tekartik-deploy-cloud
description: >-
  Use when uploading a built folder to Google Cloud Storage or an ftp/sftp host
  with tekartik_deploy: gsCopyFile, gsWebDeploy, gsWebDeployCmds,
  gsWebPrepareForRsync, gsDeployCmd, gsutilRsyncCmd, gsutilCopyCmd, gsUtilCmd,
  encodingGZipFolder / encodingNoneFolder, the gsdeploy and gswebdeploy command
  line tools, and FtpClient (lftpDeploy, ls, fromMap) from ftp_deploy.dart.
---

# Google Storage and ftp deployment (tekartik_deploy)

`package:tekartik_deploy/gs_deploy.dart` and
`package:tekartik_deploy/ftp_deploy.dart` wrap external command line tools:
`gsutil` (Google Cloud SDK) for Cloud Storage, `lftp` for ftp/sftp. They build
and run the commands; they are not API clients. Prepare the folder to upload
first (see the `tekartik-deploy-fs` skill for `fsDeploy`).

## Guidelines

* Dependency (git, not on pub.dev; single package repo, so no `path:`):
  ```yaml
  dependencies:
    tekartik_deploy:
      git:
        url: https://github.com/tekartik/deploy.dart
  ```
* Everything here shells out and is `dart:io` only: VM scripts, `tool/`,
  CI. Nothing works on the web or in Flutter.
* Prerequisites, checked at call time: `gsutil` must be in the `PATH` or
  `TEKARTIK_GOOGLE_CLOUD_SDK_DIR` must point at the Cloud SDK (the helper then
  uses `<dir>/bin/gsutil`), otherwise a `StateError` is thrown; `lftp` must be
  in the `PATH` for `FtpClient`. Authentication is whatever `gcloud auth` /
  `gsutil config` set up: the package passes no credentials.
* One-file upload: `await gsCopyFile(src, dst, {verbose})` runs
  `gsutil cp` then `gsutil -m setmeta -h "Content-Type:<mime>"`, the mime type
  being guessed from the source file name (`filenameMimeType` of
  `tekartik_app_media`, `application/octet-stream` for an unknown
  extension). A `dst`
  ending with `/` keeps the source basename
  (`gsCopyFile('out/app.js', 'gs://my-bucket/js/')`).
* Folder sync: `gsDeployCmd(src, dst, {recursive = true, parallel = true})`
  returns a `ProcessCmd` for `gsutil [-m] rsync [-r] src dst`; run it with
  `runCmd(cmd, verbose: true)` from `package:process_run/cmd_run.dart`.
  `gsutilRsyncCmd(src, dst, {recursive, parallel, useChecksum, header})` is the
  general form (`-c` for checksums, `-h Key:Value` headers), `gsutilCopyCmd`
  the `cp` variant (`-z html,css,js,json`, `-a public-read`), `gsUtilCmd(args)`
  a raw `gsutil` command. `gsutilCmd` is deprecated, use `gsUtilCmd`.
  rsync mirrors but does not delete extra remote files here. `runCmd` does
  not throw when gsutil fails: check `result.exitCode`.
* Static web site: `await gsWebDeploy(src, gsDst)` does the whole job — it
  builds `<parent>/gs/<name>/gzip` and `.../none` next to `src`
  (`gsWebPrepareForRsync`), gzips **in place** everything under the `gzip`
  folder (`.html`, `.js`, `.json`, `.appcache`, `.css`, `.txt`; everything else
  goes to `none`), then rsyncs both with `Content-Encoding: gzip` set on the
  first (`gsWebDeployCmds`). The staging folders are refreshed from `src` on
  each run (no double compression, `src` is never modified) and kept
  afterwards; a file deleted from `src` stays in them. It throws a
  `StateError` when an rsync fails, and the next one is not run.
* `encodingGZipFolder` (`'gzip'`) and `encodingNoneFolder` (`'none'`) name
  those staging subfolders. The gzip step itself is not exported: use
  `gsWebDeploy`, running `gsWebDeployCmds` on a folder prepared with
  `gsWebPrepareForRsync` alone would upload uncompressed files declared as
  gzip.
* ftp/sftp: `FtpClient()` has mutable `host`, `port`, `username`, `password`
  and `allowUnsecure` fields, or `fromMap(map)` reading the same keys from a
  decoded yaml/json map (a `.local/ftp.yaml` kept out of git).
  `lftpDeploy(src:, dst:)` runs
  `mirror --only-newer --reverse --delete --verbose`, i.e. it uploads `src` to
  `dst` **and deletes remote files that are not in `src`**. `ls(remoteDir:)`
  lists a remote folder. `allowUnsecure: true` switches the url from `sftp:` to
  `ftp:` and sets `ftp:ssl-allow no`; leave it null/false otherwise.
  `port` is appended to the host (`sftp://user:****@host:2222`). The user
  and the password are percent encoded in the lftp url (any character is
  fine), but they end up on the `lftp` command line (visible in the process
  list): the printed command hides the password, avoid other logs of them.
  A `src` or `dst` path with spaces or quotes is not supported (it goes
  unquoted in the lftp command).
* Command line: the package declares no `executables:`, run
  `dart run tekartik_deploy:gsdeploy ...` from a package depending on it, or
  `dart pub global run tekartik_deploy:gsdeploy ...` after
  `dart pub global activate -s git https://github.com/tekartik/deploy.dart`:
  * `gsdeploy <local_dir> gs://bucket/path` — the `gsDeployCmd` rsync, exits
    with gsutil's exit code when it fails;
  * `gswebdeploy <local_dir> gs://bucket/path` — the gzip web deploy, fails
    (non zero exit) when an rsync fails;
  * both take `--check` (exit code tells whether `gsutil` was found),
    `--version` and `-h`.

## Examples

### Upload one file with its content type

```dart
import 'package:tekartik_deploy/gs_deploy.dart';

Future<void> main() async {
  // Uploads to gs://my-bucket/js/main.dart.js, with the Content-Type
  // guessed from the .js extension.
  await gsCopyFile('build/web/main.dart.js', 'gs://my-bucket/js/', verbose: true);
}
```

### Sync a folder (rsync) from a tool script

```dart
import 'package:process_run/cmd_run.dart';
import 'package:tekartik_deploy/gs_deploy.dart';

Future<void> main() async {
  var result = await runCmd(
    gsDeployCmd('build/deploy', 'gs://my-bucket/app'),
    verbose: true,
  );
  // runCmd does not throw when gsutil fails
  if (result.exitCode != 0) {
    throw StateError('gsutil rsync failed (${result.exitCode})');
  }

  // Custom: checksums and a cache header, no parallelism.
  await runCmd(
    gsutilRsyncCmd(
      'build/deploy',
      'gs://my-bucket/app',
      recursive: true,
      parallel: false,
      useChecksum: true,
      header: {'Cache-Control': 'public, max-age=3600'},
    ),
    verbose: true,
  );
}
```

### Deploy a gzipped static web site

```dart
import 'dart:io';

import 'package:tekartik_deploy/gs_deploy.dart';

Future<void> main() async {
  try {
    // All in one: prepare build/gs/deploy/{gzip,none}, gzip, rsync both.
    await gsWebDeploy('build/deploy', 'gs://my-bucket/www');
  } on StateError catch (e) {
    // gsutil not found, or an rsync failed (its output is above)
    stderr.writeln(e);
    exitCode = 1;
  }
}
```

### Upload to an sftp host with lftp

```dart
import 'dart:io';

import 'package:tekartik_deploy/ftp_deploy.dart';
import 'package:yaml/yaml.dart';

Future<void> main() async {
  // .local/ftp.yaml: host/username/password (+ allowUnsecure), git ignored.
  var map = loadYaml(await File('.local/ftp.yaml').readAsString()) as Map;
  var client = FtpClient()..fromMap(map);

  await client.ls(remoteDir: '/www');
  // Mirrors: remote files missing from the source are deleted.
  await client.lftpDeploy(src: 'build/deploy', dst: '/www');
}
```

## Common mistakes

* Calling any `gs*` helper where `gsutil` is not installed/authenticated: it
  throws a `StateError` or fails in the subprocess.
* Running `gsDeployCmd` with `runCmd` and ignoring `result.exitCode`: a failed
  upload then looks like a success.
* Running `gsWebDeployCmds` on a folder that was not gzipped by
  `gsWebDeploy`: the files are declared `Content-Encoding: gzip` but are not.
* Forgetting that `lftpDeploy` deletes remote files absent from `src`.
* Using these libraries from Flutter or web code.
