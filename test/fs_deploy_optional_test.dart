@TestOn('vm')
library;

import 'package:tekartik_deploy/fs/fs_deploy.dart';
import 'package:tekartik_deploy/src/fs_deploy_impl.dart';
import 'package:tekartik_fs_test/test_common.dart';
import 'package:yaml/yaml.dart';

import 'fs_test_common_io.dart';

void main() {
  group('optional_config', () {
    test('parse', () {
      final config = Config(
        loadYaml('''
    files:
      - index.html
      - main.dart.{js,mjs,wasm}
    optional:
      - favicon.png
      - icon.png: favicon.ico
''')
            as Map?,
      );
      expect(config.entities, [
        EntityConfig('index.html'),
        EntityConfig('main.dart.{js,mjs,wasm}'),
        EntityConfig('favicon.png', optional: true),
        EntityConfig.withDst('icon.png', 'favicon.ico', optional: true),
      ]);
      expect(config.entities[1].isPattern, isTrue);
      expect(config.entities[2].isPattern, isFalse);
      expect(config.entities[2].toString(), 'favicon.png (optional)');
      expect(
        config.entities[3].toString(),
        'icon.png => favicon.ico (optional)',
      );
      expect(EntityConfig('a'), isNot(EntityConfig('a', optional: true)));
    });

    test('optional only', () {
      final config = Config({
        'optional': {'file1': null},
      });
      expect(config.entities, [EntityConfig('file1', optional: true)]);
    });

    test('deployPathIsPattern', () {
      expect(deployPathIsPattern('index.html'), isFalse);
      expect(deployPathIsPattern('icons/'), isFalse);
      expect(deployPathIsPattern('flutter*.js'), isTrue);
      expect(deployPathIsPattern('file?.txt'), isTrue);
      expect(deployPathIsPattern('main.dart.{js,wasm}'), isTrue);
    });

    test('deployPathExpandBraces', () {
      expect(deployPathExpandBraces('index.html'), ['index.html']);
      expect(deployPathExpandBraces('main.dart.{js,mjs,wasm}'), [
        'main.dart.js',
        'main.dart.mjs',
        'main.dart.wasm',
      ]);
      expect(deployPathExpandBraces('{a,b}{c,d}'), ['ac', 'ad', 'bc', 'bd']);
      expect(deployPathExpandBraces('x{a,{b,c}}'), ['xa', 'xb', 'xc']);
      expect(deployPathExpandBraces('{a,}b'), ['ab', 'b']);
      expect(deployPathExpandBraces('{a,a}'), ['a']);
      expect(deployPathExpandBraces('a{b'), ['a{b']);
    });
  });
  group('memory', () {
    defineTests(memoryFileSystemTestContext);
  });
  group('io', () {
    defineTests(FileSystemTestContextIo('fs_deploy_optional'));
  });
}

void defineTests(FileSystemTestContext ctx) {
  final fs = ctx.fs;

  late Directory top;
  late Directory src;
  late Directory dst;

  /// Flutter web build without wasm nor service worker.
  Future<void> prepareFlutterBuild() async {
    top = await ctx.prepare();
    src = childDirectory(top, 'src');
    dst = childDirectory(top, 'dst');
    for (var path in [
      'index.html',
      'main.dart.js',
      'flutter.js',
      'flutter_bootstrap.js',
      'manifest.json',
      'version.json',
      'favicon.png',
      '.last_build_id',
      'assets/AssetManifest.bin',
      'assets/fonts/MaterialIcons-Regular.otf',
      'icons/Icon-192.png',
      'icons/Icon-512.png',
      'icons/.hidden',
    ]) {
      await writeString(fs.file(fs.path.join(src.path, path)), path);
    }
  }

  Future<List<String>> dstFiles() async {
    return [
      await for (var entity in dst.list(recursive: true))
        if (await fs.isFile(entity.path))
          fs.path
              .relative(entity.path, from: dst.path)
              .replaceAll(fs.path.separator, '/'),
    ]..sort();
  }

  Future<List<String>> listFiles(Map<Object?, Object?> settings) async {
    return [
      for (var file in await fsDeployListFiles(settings: settings, src: src))
        fs.path
            .relative(file.path, from: src.path)
            .replaceAll(fs.path.separator, '/'),
    ]..sort();
  }

  group('optional', () {
    test('optional files', () async {
      await prepareFlutterBuild();
      final settings =
          loadYaml('''
files:
  - index.html
  - main.dart.js
  - flutter.js
  - flutter_bootstrap.js
  - manifest.json
  - version.json
  - assets/
optional:
  - main.dart.mjs
  - main.dart.wasm
  - flutter_service_worker.js
  - favicon.png
  - icons/
''')
              as Map<Object?, Object?>;
      final count = await fsDeploy(settings: settings, src: src, dst: dst);
      final expected = [
        'assets/AssetManifest.bin',
        'assets/fonts/MaterialIcons-Regular.otf',
        'favicon.png',
        'flutter.js',
        'flutter_bootstrap.js',
        'icons/.hidden',
        'icons/Icon-192.png',
        'icons/Icon-512.png',
        'index.html',
        'main.dart.js',
        'manifest.json',
        'version.json',
      ];
      expect(await dstFiles(), expected);
      expect(count, expected.length);
      expect(await readString(childFile(dst, 'favicon.png')), 'favicon.png');
      expect(await listFiles(settings), expected);
    });

    test('missing required file', () async {
      await prepareFlutterBuild();
      await expectLater(
        fsDeploy(
          settings: {
            'files': ['index.html', 'main.dart.wasm'],
          },
          src: src,
          dst: dst,
        ),
        throwsA(anything),
      );
    });

    test('patterns', () async {
      await prepareFlutterBuild();
      final settings =
          loadYaml('''
files:
  - index.html
  - main.dart.{js,mjs,wasm}   # whatever exists
  - flutter*.js
  - icons/
  - assets/
''')
              as Map<Object?, Object?>;
      final count = await fsDeploy(settings: settings, src: src, dst: dst);
      final expected = [
        'assets/AssetManifest.bin',
        'assets/fonts/MaterialIcons-Regular.otf',
        'flutter.js',
        'flutter_bootstrap.js',
        'icons/.hidden',
        'icons/Icon-192.png',
        'icons/Icon-512.png',
        'index.html',
        'main.dart.js',
      ];
      expect(await dstFiles(), expected);
      expect(count, expected.length);
      expect(await listFiles(settings), expected);
    });

    test('pattern in sub dir and dot files', () async {
      await prepareFlutterBuild();
      final count = await fsDeploy(
        settings: {
          'files': ['icons/*', '*.json'],
          'optional': ['.last*', 'none/*.png'],
        },
        src: src,
        dst: dst,
      );
      final expected = [
        '.last_build_id',
        'icons/Icon-192.png',
        'icons/Icon-512.png',
        'manifest.json',
        'version.json',
      ];
      expect(await dstFiles(), expected);
      expect(count, expected.length);
    });

    test('pattern matching a directory', () async {
      await prepareFlutterBuild();
      await fsDeploy(
        settings: {
          'files': ['a*'],
        },
        src: src,
        dst: dst,
      );
      expect(await dstFiles(), [
        'assets/AssetManifest.bin',
        'assets/fonts/MaterialIcons-Regular.otf',
      ]);
    });

    test('pattern no match', () async {
      await prepareFlutterBuild();
      // optional, nothing deployed
      expect(
        await fsDeploy(
          settings: {
            'optional': ['*.wasm'],
          },
          src: src,
          dst: dst,
        ),
        0,
      );
      expect(await dstFiles(), isEmpty);
      expect(
        await listFiles({
          'optional': ['*.wasm'],
        }),
        isEmpty,
      );

      // required
      await expectLater(
        fsDeploy(
          settings: {
            'files': ['*.wasm'],
          },
          src: src,
          dst: dst,
        ),
        throwsStateError,
      );
    });

    test('pattern rename', () async {
      await prepareFlutterBuild();
      await expectLater(
        fsDeploy(
          settings: {
            'files': [
              {'*.js': 'js'},
            ],
          },
          src: src,
          dst: dst,
        ),
        throwsArgumentError,
      );
    });

    test('optional rename', () async {
      await prepareFlutterBuild();
      await fsDeploy(
        settings: {
          'optional': [
            {'favicon.png': 'favicon.ico'},
            {'missing.png': 'other.ico'},
          ],
        },
        src: src,
        dst: dst,
      );
      expect(await dstFiles(), ['favicon.ico']);
    });
  });
}
