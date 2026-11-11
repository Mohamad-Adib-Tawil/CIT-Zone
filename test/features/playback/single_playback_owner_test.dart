import 'dart:async';

import 'package:cit_zone/core/errors/either.dart';
import 'package:cit_zone/core/media/media_failure.dart';
import 'package:cit_zone/features/playback/domain/playback_repository.dart';
import 'package:cit_zone/features/playback/domain/single_playback_owner.dart';
import 'package:flutter_test/flutter_test.dart';

const request = PlaybackRequest(
  assetId: 'test_asset',
  mode: PlaybackMode.streaming,
);

void main() {
  test(
    'concurrent opens close the previous session before creating another',
    () async {
      var active = 0;
      var maximum = 0;
      var opens = 0;
      final release = Completer<void>();
      final owner = SinglePlaybackOwner(
        _Repository(() async {
          opens++;
          if (opens == 1) await release.future;
          active++;
          if (active > maximum) maximum = active;
          return Right(
            _Session(() async {
              active--;
              return const Right(null);
            }),
          );
        }),
      );
      final first = owner.open(request);
      final second = owner.open(request);
      await Future<void>.delayed(Duration.zero);
      expect(opens, 1);
      release.complete();
      expect(await first, isA<Right<MediaFailure, PlaybackSession>>());
      expect(await second, isA<Right<MediaFailure, PlaybackSession>>());
      expect(opens, 2);
      expect(maximum, 1);
      expect(active, 1);
      await owner.dispose();
      expect(active, 0);
    },
  );

  test('failed close blocks replacement and retains the resource for cleanup retry', () async {
    var opens = 0;
    var closeAllowed = false;
    var closes = 0;
    final owner = SinglePlaybackOwner(
      _Repository(() async {
        opens++;
        return Right(
          _Session(() async {
            closes++;
            return closeAllowed
                ? const Right(null)
                : const Left(MediaFailure.unexpected);
          }),
        );
      }),
    );
    await owner.open(request);
    expect(
      await owner.open(request),
      isA<Left<MediaFailure, PlaybackSession>>(),
    );
    expect(opens, 1);
    expect(closes, 1);
    closeAllowed = true;
    expect(await owner.dispose(), isA<Right<MediaFailure, void>>());
    expect(closes, 2);
    expect(
      await owner.open(request),
      isA<Left<MediaFailure, PlaybackSession>>(),
    );
    expect(opens, 1);
  });

  test(
    'dispose during open releases a late resource and cancels queued opens',
    () async {
      final pending = Completer<Either<MediaFailure, PlaybackSession>>();
      var closes = 0;
      final owner = SinglePlaybackOwner(_Repository(() => pending.future));
      final opening = owner.open(request);
      await Future<void>.delayed(Duration.zero);
      final disposal = owner.dispose();
      pending.complete(
        Right(
          _Session(() async {
            closes++;
            return const Right(null);
          }),
        ),
      );
      final opened = await opening;
      expect(
        opened.match((failure) => failure, (_) => null),
        MediaFailure.canceled,
      );
      expect(await disposal, isA<Right<MediaFailure, void>>());
      expect(closes, 1);
    },
  );

  test(
    'license or entitlement denial never creates a playable session',
    () async {
      final owner = SinglePlaybackOwner(
        _Repository(() async => const Left(MediaFailure.notEntitled)),
      );
      final result = await owner.open(request);
      expect(
        result.match((failure) => failure, (_) => null),
        MediaFailure.notEntitled,
      );
      expect(await owner.dispose(), isA<Right<MediaFailure, void>>());
    },
  );
}

class _Repository implements PlaybackRepository {
  _Repository(this.openSession);
  final Future<Either<MediaFailure, PlaybackSession>> Function() openSession;
  @override
  Future<Either<MediaFailure, PlaybackSession>> open(PlaybackRequest request) =>
      openSession();
}

class _Session implements PlaybackSession {
  _Session(this.onClose);
  final Future<Either<MediaFailure, void>> Function() onClose;
  @override
  Future<Either<MediaFailure, void>> close() => onClose();
  @override
  Future<Either<MediaFailure, void>> pause() async => const Right(null);
  @override
  Future<Either<MediaFailure, void>> play() async => const Right(null);
  @override
  Future<Either<MediaFailure, void>> seek(Duration position) async =>
      const Right(null);
}
