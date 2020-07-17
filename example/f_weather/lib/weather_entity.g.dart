// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Coord _$CoordFromJson(Map<String, dynamic> json) {
  return Coord(
    (json['lat'] as num)?.toDouble(),
    (json['lon'] as num)?.toDouble(),
  );
}

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) {
  return WeatherData(
    (json['temp'] as num)?.toDouble(),
    (json['pressure'] as num)?.toDouble(),
    (json['humidity'] as num)?.toDouble(),
    (json['temp_min'] as num)?.toDouble(),
    (json['temp_max'] as num)?.toDouble(),
  );
}

Wind _$WindFromJson(Map<String, dynamic> json) {
  return Wind(
    (json['speed'] as num)?.toDouble(),
    (json['deg'] as num)?.toDouble(),
  );
}

WeatherSys _$WeatherSysFromJson(Map<String, dynamic> json) {
  return WeatherSys(
    json['type'] as int,
    json['id'] as int,
    (json['message'] as num)?.toDouble(),
    json['country'] as String,
    json['sunrise'] as int,
    json['sunset'] as int,
  );
}

Weather _$WeatherFromJson(Map<String, dynamic> json) {
  return Weather(
    json['id'] as int,
    json['coord'] == null ? null : Coord.fromJson(json['coord'] as Map<String, dynamic>),
    json['main'] == null ? null : WeatherData.fromJson(json['main'] as Map<String, dynamic>),
    json['wind'] == null ? null : Wind.fromJson(json['wind'] as Map<String, dynamic>),
    json['sys'] == null ? null : WeatherSys.fromJson(json['sys'] as Map<String, dynamic>),
    json['name'] as String,
  );
}
