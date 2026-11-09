import 'dart:io';

import 'package:path/path.dart';
import 'package:tekartik_deploy/fs_deploy.dart';

/// Deploys a fake build folder, in a temporary folder deleted at the end.
Future<void> main() async {
  var top = await Directory.systemTemp.createTemp('tekartik_deploy_example');
  try {
    // A build output
    var build = Directory(join(top.path, 'build', 'web'));
    for (var path in [
      'index.html',
      'main.dart.js',
      'main.dart.js.map',
      join('assets', 'logo.png'),
    ]) {
      await File(join(build.path, path)).create(recursive: true);
    }
    // What ships, read from build/web/deploy.yaml
    var yaml = File(join(build.path, 'deploy.yaml'));
    await yaml.writeAsString('''
files:
  - index.html
  - main.dart.{js,mjs,wasm}
  - assets
optional:
  - favicon.png
''');

    // Dry run: the files that would be deployed
    for (var file in await fsDeployListFiles(yaml: yaml)) {
      stdout.writeln('to deploy: ${relative(file.path, from: build.path)}');
    }

    // Deploy to build/deploy (deleted first), real copies
    var deploy = Directory(join(top.path, 'build', 'deploy'));
    var count = await fsDeploy(
      yaml: yaml,
      dst: deploy,
      options: fsDeployOptionsNoSymLink,
    );
    stdout.writeln('$count file(s) deployed');
    await for (var entity in deploy.list(recursive: true)) {
      if (entity is File) {
        stdout.writeln('deployed: ${relative(entity.path, from: deploy.path)}');
      }
    }
  } finally {
    await top.delete(recursive: true);
  }
}
