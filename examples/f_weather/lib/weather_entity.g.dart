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

Map<String, dynamic> _$CoordToJson(Coord instance) => <String, dynamic>{
      'lat': instance.lat,
      'lon': instance.lon,
    };

WeatherData _$WeatherDataFromJson(Map<String, dynamic> json) {
  return WeatherData(
    (json['temp'] as num)?.toDouble(),
    (json['pressure'] as num)?.toDouble(),
    (json['humidity'] as num)?.toDouble(),
    (json['temp_min'] as num)?.toDouble(),
    (json['temp_max'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$WeatherDataToJson(WeatherData instance) =>
    <String, dynamic>{
      'temp': instance.temp,
      'pressure': instance.pressure,
      'humidity': instance.humidity,
      'temp_min': instance.tempMin,
      'temp_max': instance.tempMax,
    };

Wind _$WindFromJson(Map<String, dynamic> json) {
  return Wind(
    (json['speed'] as num)?.toDouble(),
    (json['deg'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$WindToJson(Wind instance) => <String, dynamic>{
      'speed': instance.speed,
      'deg': instance.deg,
    };

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

Map<String, dynamic> _$WeatherSysToJson(WeatherSys instance) =>
    <String, dynamic>{
      'type': instance.type,
      'id': instance.id,
      'message': instance.message,
      'country': instance.country,
      'sunrise': instance.sunrise,
      'sunset': instance.sunset,
    };

Weather _$WeatherFromJson(Map<String, dynamic> json) {
  return Weather(
    json['id'] as int,
    json['coord'] == null
        ? null
        : Coord.fromJson(json['coord'] as Map<String, dynamic>),
    json['main'] == null
        ? null
        : WeatherData.fromJson(json['main'] as Map<String, dynamic>),
    json['wind'] == null
        ? null
        : Wind.fromJson(json['wind'] as Map<String, dynamic>),
    json['sys'] == null
        ? null
        : WeatherSys.fromJson(json['sys'] as Map<String, dynamic>),
    json['name'] as String,
  );
}

Map<String, dynamic> _$WeatherToJson(Weather instance) => <String, dynamic>{
      'id': instance.id,
      'coord': instance.coord,
      'main': instance.data,
      'wind': instance.wind,
      'sys': instance.sys,
      'name': instance.name,
    };
