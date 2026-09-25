import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gimmy/core/config/feature_flags.dart';
import 'package:gimmy/data/exercises/exercise_catalog.dart';
import 'package:gimmy/data/exercises/exercise_media_store_io.dart';

const _pushUp = CatalogEntry(
  id: '0662',
  name: 'push-up',
  equipment: 'body weight',
  gif: 'videos/0662-I4hDWkc.gif',
  image: 'images/0662-I4hDWkc.jpg',
);

const _squat = CatalogEntry(
  id: '0001',
  name: 'squat',
  equipment: 'body weight',
  gif: 'videos/0001-x.gif',
  image: 'images/0001-x.jpg',
);

void main() {
  late Directory dir;
  late List<Uri> requested;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('media_test');
    requested = [];
  });

  tearDown(() => dir.deleteSync(recursive: true));

  FileExerciseMediaStore store({Set<String> failing = const {}}) =>
      FileExerciseMediaStore(
        directory: dir,
        fetch: (uri) async {
          requested.add(uri);
          if (failing.any(uri.path.endsWith)) {
            throw const HttpException('503');
          }
          return [1, 2, 3];
        },
      );

  String? pathOf(ImageProvider? image) => (image as FileImage?)?.file.path;

  test(
    'prefetch downloads the demo and the still from the pinned repo',
    () async {
      await store().prefetch([_pushUp]);

      expect(requested, [
        Uri.parse('${AppConfig.exerciseMediaBaseUrl}/videos/0662-I4hDWkc.gif'),
        Uri.parse('${AppConfig.exerciseMediaBaseUrl}/images/0662-I4hDWkc.jpg'),
      ]);
      expect(
        File('${dir.path}/exercise_media/videos/0662-I4hDWkc.gif')
            .readAsBytesSync(),
        [1, 2, 3],
      );
    },
  );

  test('a downloaded demo is served from disk, animated or still', () async {
    final media = store();
    await media.prefetch([_pushUp]);

    expect(pathOf(await media.demoFor(_pushUp)), endsWith('0662-I4hDWkc.gif'));
    expect(
      pathOf(await media.demoFor(_pushUp, still: true)),
      endsWith('0662-I4hDWkc.jpg'),
    );
  });

  test('media already on disk is not fetched again', () async {
    await store().prefetch([_pushUp]);
    requested.clear();

    await store().prefetch([_pushUp]);

    expect(requested, isEmpty);
  });

  test(
    'a failed download costs that demo only, and leaves no scraps',
    () async {
      final media = store(failing: {'0001-x.gif'});

      await media.prefetch([_squat, _pushUp]);

      expect(await media.demoFor(_squat), isNull);
      expect(await media.demoFor(_pushUp), isNotNull);
      final leftovers = dir
          .listSync(recursive: true)
          .where((f) => f.path.endsWith('.tmp'));
      expect(leftovers, isEmpty);
    },
  );

  test('an empty response is a failed download, not a demo', () async {
    final media = FileExerciseMediaStore(
      directory: dir,
      fetch: (_) async => const [],
    );

    await media.prefetch([_pushUp]);

    expect(await media.demoFor(_pushUp), isNull);
  });

  test('nothing downloaded means no demo', () async {
    expect(await store().demoFor(_pushUp), isNull);
  });
}
