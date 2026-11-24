import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Runs a bloc's events one at a time, in the order they were added, across
/// all event types. (bloc's `sequential()` only orders events of one type: a
/// Cancel could otherwise run while a Start still waits for mxclockd.)
///
/// One per bloc: `on<StartTimer>(_onStart, transformer: _inOrder());`.
class InOrder {
  Future<void> _last = Future.value();

  EventTransformer<E> call<E>() =>
      (events, mapper) => concurrent<E>()(events, (event) {
        // Set when the bloc closes: a queued event is then dropped.
        var cancelled = false;
        final run = _last.then((_) async {
          if (!cancelled) await mapper(event).drain<void>();
        });
        // A failed handler doesn't hold up the events after it.
        _last = run.catchError((Object _) {});

        final done = StreamController<E>(onCancel: () => cancelled = true);
        run.then(
          (_) => done.close(),
          onError: (Object e, StackTrace s) => done
            ..addError(e, s)
            ..close(),
        );
        return done.stream;
      });
}
