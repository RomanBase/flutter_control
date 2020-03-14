import 'dart:convert';

import 'package:f_weather/weather_entity.dart';
import 'package:flutter_control/core.dart';
import 'package:http/http.dart';

/// https://openweathermap.org/current
class WeatherRepo {
  final url = 'https://api.openweathermap.org/data/2.5/weather';
  final key = '9cf201bc7a9a4677e63fdecda265a110';
  final units = 'metric';

  Future<Weather> getWeatherByCity(String cityName) async {
    final result = await get('$url?q=$cityName&units=$units&appid=$key');

    printDebug(result.body);

    if (result.statusCode != 200) {
      throw Parse.getArgFromString(result.body, key: 'message', defaultValue: 'something went wrong');
    }

    return Weather.fromJson(jsonDecode(result.body));
  }

  Future<Weather> getWeatherByGps(double lat, double lng) async {
    final result = await get('$url?lat=$lat&lon=$lng&units=$units&appid=$key');

    if (result.statusCode != 200) {
      throw 'something wen wrong';
    }

    return Weather.fromJson(jsonDecode(result.body));
  }
}

mixin WeatherProvider {
  WeatherRepo _repo;

  WeatherRepo get weather => _repo ?? (_repo = Control.init<WeatherRepo>());
}
