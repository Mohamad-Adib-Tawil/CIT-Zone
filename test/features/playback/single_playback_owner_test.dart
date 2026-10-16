import 'dart:async';

import 'package:cit_zone/core/errors/result.dart';
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
          return Success(
            _Session(() async {
              active--;
              return const Success(null);
            }),
          );
        }),
      );
      final first = owner.open(request);
      final second = owner.open(request);
      await Future<void>.delayed(Duration.zero);
      expect(opens, 1);
      release.complete();
      expect(await first, isA<Success<PlaybackSession, MediaFailure>>());
      expect(await second, isA<Success<PlaybackSession, MediaFailure>>());
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
        return Success(
          _Session(() async {
            closes++;
            return closeAllowed
                ? const Success(null)
                : const Failure(MediaFailure.unexpected);
          }),
        );
      }),
    );
    await owner.open(request);
    expect(
      await owner.open(request),
      isA<Failure<PlaybackSession, MediaFailure>>(),
    );
    expect(opens, 1);
    expect(closes, 1);
    closeAllowed = true;
    expect(await owner.dispose(), isA<Success<void, MediaFailure>>());
    expect(closes, 2);
    expect(
      await owner.open(request),
      isA<Failure<PlaybackSession, MediaFailure>>(),
    );
    expect(opens, 1);
  });

  test(
    'dispose during open releases a late resource and cancels queued opens',
    () async {
      final pending = Completer<Result<PlaybackSession, MediaFailure>>();
      var closes = 0;
      final owner = SinglePlaybackOwner(_Repository(() => pending.future));
      final opening = owner.open(request);
      await Future<void>.delayed(Duration.zero);
      final disposal = owner.dispose();
      pending.complete(
        Success(
          _Session(() async {
            closes++;
            return const Success(null);
          }),
        ),
      );
      final opened = await opening;
      expect(
        opened.fold(onSuccess: (_) => null, onFailure: (failure) => failure),
        MediaFailure.canceled,
      );
      expect(await disposal, isA<Success<void, MediaFailure>>());
      expect(closes, 1);
    },
  );

  test(
    'license or entitlement denial never creates a playable session',
    () async {
      final owner = SinglePlaybackOwner(
        _Repository(() async => const Failure(MediaFailure.notEntitled)),
      );
      final result = await owner.open(request);
      expect(
        result.fold(onSuccess: (_) => null, onFailure: (failure) => failure),
        MediaFailure.notEntitled,
      );
      expect(await owner.dispose(), isA<Success<void, MediaFailure>>());
    },
  );
}

class _Repository implements PlaybackRepository {
  _Repository(this.openSession);
  final Future<Result<PlaybackSession, MediaFailure>> Function() openSession;
  @override
  Future<Result<PlaybackSession, MediaFailure>> open(PlaybackRequest request) =>
      openSession();
}

class _Session implements PlaybackSession {
  _Session(this.onClose);
  final Future<Result<void, MediaFailure>> Function() onClose;
  @override
  Future<Result<void, MediaFailure>> close() => onClose();
  @override
  Future<Result<void, MediaFailure>> pause() async => const Success(null);
  @override
  Future<Result<void, MediaFailure>> play() async => const Success(null);
  @override
  Future<Result<void, MediaFailure>> seek(Duration position) async =>
      const Success(null);
}
