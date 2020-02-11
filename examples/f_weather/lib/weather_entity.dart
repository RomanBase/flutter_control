import 'package:json_annotation/json_annotation.dart';

part 'weather_entity.g.dart';

@JsonSerializable()
class Coord {
  final double lat;
  final double lon;

  Coord(this.lat, this.lon);

  factory Coord.fromJson(Map json) => _$CoordFromJson(json);
}

@JsonSerializable()
class WeatherData {
  final double temp;
  final double pressure;
  final double humidity;

  @JsonKey(name: 'temp_min')
  final double tempMin;

  @JsonKey(name: 'temp_max')
  final double tempMax;

  WeatherData(this.temp, this.pressure, this.humidity, this.tempMin, this.tempMax);

  factory WeatherData.fromJson(Map json) => _$WeatherDataFromJson(json);
}

@JsonSerializable()
class Wind {
  final double speed;
  final double deg;

  Wind(this.speed, this.deg);

  factory Wind.fromJson(Map json) => _$WindFromJson(json);
}

@JsonSerializable()
class WeatherSys {
  final int type;
  final int id;
  final double message;
  final String country;
  final int sunrise;
  final int sunset;

  WeatherSys(this.type, this.id, this.message, this.country, this.sunrise, this.sunset);

  factory WeatherSys.fromJson(Map json) => _$WeatherSysFromJson(json);
}

@JsonSerializable()
class Weather {
  final int id;
  final Coord coord;

  @JsonKey(name: 'main')
  final WeatherData data;

  final Wind wind;
  final WeatherSys sys;
  final String name;

  String get nameWithCountry => sys?.country != null ? '$name, ${sys.country}' : name;

  Weather(this.id, this.coord, this.data, this.wind, this.sys, this.name);

  factory Weather.fromJson(Map json) => _$WeatherFromJson(json);
}
