import 'package:equatable/equatable.dart';

class WorldClock extends Equatable {
  final String id;
  final String cityName;
  final String country;
  final String timezoneId;

  const WorldClock({
    required this.id,
    required this.cityName,
    required this.country,
    required this.timezoneId,
  });

  WorldClock copyWith({
    String? id,
    String? cityName,
    String? country,
    String? timezoneId,
  }) {
    return WorldClock(
      id: id ?? this.id,
      cityName: cityName ?? this.cityName,
      country: country ?? this.country,
      timezoneId: timezoneId ?? this.timezoneId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cityName': cityName,
      'country': country,
      'timezoneId': timezoneId,
    };
  }

  factory WorldClock.fromJson(Map<String, dynamic> json) {
    return WorldClock(
      id: json['id'] as String,
      cityName: json['cityName'] as String,
      country: json['country'] as String,
      timezoneId: json['timezoneId'] as String,
    );
  }

  @override
  List<Object?> get props => [id, cityName, country, timezoneId];
}
