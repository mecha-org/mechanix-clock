import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/core/utils/in_order.dart';

sealed class _Event {}

class _Slow extends _Event {
  _Slow(this.name);
  final String name;
}

class _Fast extends _Event {}

class _Fail extends _Event {}

class _Bloc extends Bloc<_Event, List<String>> {
  _Bloc() : super(const []) {
    on<_Slow>((event, emit) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      emit([...state, event.name]);
    }, transformer: _inOrder());
    on<_Fast>((_, emit) => emit([...state, 'fast']), transformer: _inOrder());
    on<_Fail>((_, _) => throw StateError('fail'), transformer: _inOrder());
  }

  final _inOrder = InOrder();
}

void main() {
  test('events of different types run one at a time, in order', () async {
    final bloc = _Bloc()
      ..add(_Slow('a'))
      ..add(_Slow('b'))
      ..add(_Fast())
      ..add(_Slow('c'));
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(bloc.state, ['a', 'b', 'fast', 'c']);
    await bloc.close();
  });

  test('a failing handler does not hold up the next events', () async {
    final errors = <Object>[];
    late _Bloc bloc;
    await runZonedGuarded(() async {
      bloc = _Bloc()
        ..add(_Fail())
        ..add(_Fast());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }, (error, _) => errors.add(error));
    expect(bloc.state, ['fast']);
    expect(errors, hasLength(1));
    await bloc.close();
  });

  test('events still queued when the bloc closes are dropped', () async {
    final bloc = _Bloc()
      ..add(_Slow('a'))
      ..add(_Slow('b'));
    await Future<void>.delayed(const Duration(milliseconds: 5));
    await bloc.close();
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state, isEmpty);
  });
}
