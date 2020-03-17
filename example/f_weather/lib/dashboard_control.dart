import 'package:f_weather/weather_repo.dart';
import 'package:flutter_control/core.dart';
import 'package:geolocator/geolocator.dart';

class LocationModel extends ControlModel with StateControl {
  bool _isPermissionGranted = false;

  bool get isPermissionGranted => _isPermissionGranted;

  double _lat;

  double get lat => _lat;

  double _lng;

  double get lng => _lng;

  String _place;

  String get place => _place;

  bool get isAvailable => _lat != null && _lng != null;

  Future<bool> checkPermission() async {
    final status = await Geolocator().checkGeolocationPermissionStatus();

    _isPermissionGranted = status == GeolocationStatus.granted;

    return _isPermissionGranted;
  }

  Future<void> requestCurrentGps() async {
    final position = await Geolocator().getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setPlace(position.latitude, position.longitude, '-');
  }

  void setPlace(double lat, double lng, String name) {
    _lat = lat;
    _lng = lng;
    _place = name;

    notifyState();
  }
}

class TemperatureModel extends ControlModel with StateControl {
  double _temperature;

  double get temperature => _temperatureByUnit(_temperature);

  double get temperatureC => _temperature;

  double get temperatureF => _toF(_temperature);

  double _low;

  double get low => _temperatureByUnit(_low);

  double _high;

  double get high => _temperatureByUnit(_high);

  TemperatureUnit _unit = TemperatureUnit.C;

  TemperatureUnit get unit => _unit;

  set unit(TemperatureUnit value) {
    _unit = value;
    notifyState();
  }

  String get unitSign => unit == TemperatureUnit.C ? 'C' : 'F';

  bool get isAvailable => _temperature != null;

  void setTemperatures({
    @required double temperature,
    double low,
    double high,
    TemperatureUnit unit: TemperatureUnit.C,
  }) {
    assert(temperature != null);

    if (unit == TemperatureUnit.C) {
      _temperature = temperature;
      _low = low ?? temperature - 4;
      _high = high ?? temperature + 4;
    } else {
      _temperature = _toC(temperature);
      _low = _toC(low ?? temperature - 4);
      _high = _toC(high ?? temperature + 4);
    }

    notifyState();
  }

  double _temperatureByUnit(double value) {
    switch (unit) {
      case TemperatureUnit.C:
        return value;
      case TemperatureUnit.F:
        return _toF(value);
    }

    return 0.0;
  }

  double _toC(double value) => (value - 32) * (5 / 9);

  double _toF(double value) => value * (5 / 9) + 32;
}

enum TemperatureUnit { C, F }

class DashboardControl extends BaseControl with WeatherProvider {
  final loading = LoadingControl();

  final location = LocationModel();
  final temperature = TemperatureModel();

  final city = InputControl();

  @override
  void onInit(Map args) {
    super.onInit(args);

    location.checkPermission().then((value) {
      if (value) {
        submitGps();
      }
    });

    city.done(submitCity);
  }

  void submitCity() {
    if (city.isEmpty) {
      return;
    }

    String value = city.value;

    city.clear();
    city.focus(false);

    loading.progress();

    weather.getWeatherByCity(value).then((weather) {
      location.setPlace(weather.coord.lat, weather.coord.lon, weather.nameWithCountry);

      temperature.setTemperatures(
        temperature: weather.data.temp,
        low: weather.data.tempMin,
        high: weather.data.tempMax,
        unit: TemperatureUnit.C,
      );

      loading.done();
    }).catchError((err) {
      loading.error(msg: err.toString());
    });
  }

  void submitGps() async {
    loading.progress();

    if (location.isPermissionGranted) {
      if (await location.checkPermission()) {
        printDebug('permission granted');
      } else {
        printDebug('permission rejected');
        loading.done();
        return;
      }
    }

    await location.requestCurrentGps();

    weather.getWeatherByGps(location.lat, location.lng).then((weather) {
      location.setPlace(weather.coord.lat, weather.coord.lon, weather.nameWithCountry);

      temperature.setTemperatures(
        temperature: weather.data.temp,
        low: weather.data.tempMin,
        high: weather.data.tempMax,
        unit: TemperatureUnit.C,
      );

      loading.done();
    }).catchError((err) {
      loading.error(msg: err.toString());
    });
  }
}
