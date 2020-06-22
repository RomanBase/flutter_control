import 'package:f_weather/dashboard_control.dart';
import 'package:f_weather/dashboard_page.dart';
import 'package:f_weather/weather_repo.dart';
import 'package:flutter_control/core.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      entries: {
        DashboardControl: DashboardControl(),
      },
      initializers: {
        WeatherRepo: (_) => WeatherRepo(),
      },
      states: [
        AppState.main.build((context) => DashboardPage()),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        home: home,
        title: 'Weather - Flutter Control',
      ),
    );
  }
}
