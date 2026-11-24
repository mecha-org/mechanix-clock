import 'package:flutter_test/flutter_test.dart';
import 'package:mechanix_clock/features/world_clock/data/models/world_clock_model.dart';
import 'package:mechanix_clock/features/world_clock/data/repository/world_clock_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late WorldClockRepository repository;

  const kolkata = WorldClock(
    id: '1',
    cityName: 'Kolkata',
    country: 'India',
    timezoneId: 'Asia/Kolkata',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    repository = WorldClockRepository();
  });

  test('empty when nothing is saved', () async {
    expect(await repository.getWorldClocks(), isEmpty);
  });

  test('saved clocks are read back in order', () async {
    final london = kolkata.copyWith(
      id: '2',
      cityName: 'London',
      country: 'United Kingdom',
      timezoneId: 'Europe/London',
    );
    await repository.saveWorldClocks([kolkata, london]);
    expect(await repository.getWorldClocks(), [kolkata, london]);
  });

  test('empty when the saved value is broken', () async {
    SharedPreferences.setMockInitialValues({'world_clocks_list': '{bad'});
    expect(await repository.getWorldClocks(), isEmpty);
  });

  test('WorldClock JSON round trip and copyWith', () {
    expect(WorldClock.fromJson(kolkata.toJson()), kolkata);
    expect(kolkata.copyWith(), kolkata);
    expect(kolkata.copyWith(cityName: 'Calcutta').cityName, 'Calcutta');
  });
}
