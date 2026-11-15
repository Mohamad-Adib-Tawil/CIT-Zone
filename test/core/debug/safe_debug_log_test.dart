import 'package:cit_zone/core/debug/safe_debug_log.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('error diagnostics never stringify the exception payload', () {
    final messages = <String>[];
    final previous = debugPrint;
    debugPrint = (message, {wrapWidth}) => messages.add(message ?? '');
    addTearDown(() => debugPrint = previous);

    final error = _PrivateError();
    SafeDebugLog.error('State', error, StackTrace.fromString('test frame'));

    expect(error.stringifyCalls, 0);
    expect(messages.single, contains('_PrivateError'));
    expect(messages.single, contains('test frame'));
    expect(messages.single, isNot(contains('private submission')));
  });
}

class _PrivateError implements Exception {
  int stringifyCalls = 0;

  @override
  String toString() {
    stringifyCalls++;
    return 'private submission';
  }
}
