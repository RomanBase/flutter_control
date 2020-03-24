import 'dart:ui';

import 'package:f_weather/dashboard_control.dart';
import 'package:flutter_control/core.dart';

class _UIControl extends ControlModel with TickerComponent {
  AnimationController inputAnim;

  DashboardControl get control => Control.get<DashboardControl>();

  @override
  void init(Map args) {
    super.init(args);

    control.city.onFocusChanged((focused) {
      if (focused) {
        inputAnim?.forward();
      } else {
        inputAnim?.reverse();
      }
    });
  }

  @override
  void onTickerInitialized(TickerProvider ticker) {
    inputAnim = new AnimationController(vsync: ticker, duration: Duration(milliseconds: 300));
  }

  void showInput() => control.city.focus(true);

  void hideInput() => control.city.focus(false);

  Future<bool> popScope() async {
    if (control.city.hasFocus) {
      control.city.focus(false);
      return false;
    }

    return true;
  }

  @override
  void dispose() {
    super.dispose();

    inputAnim?.dispose();
    inputAnim = null;
  }
}

class DashboardPage extends ControlWidget with TickerControl {
  DashboardControl get control => controls[0];

  _UIControl get ui => controls[1];

  @override
  List<ControlModel> initControls() => [
        Control.get<DashboardControl>(),
        _UIControl(),
      ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: ui.popScope,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            SingleChildScrollView(
              child: NotifierBuilder<TemperatureModel>(
                control: control.temperature.state,
                builder: (context, temperature) {
                  return TweenAnimationBuilder(
                    duration: Duration(milliseconds: 500),
                    curve: Curves.ease,
                    tween: ColorTween(begin: Colors.white, end: temperature.isAvailable ? Color.lerp(Color(0xFF0000FF), Colors.white, (temperature.temperatureC / 30.0).clamp(0.0, 1.0)) : Colors.white),
                    builder: (context, value, child) => Image.asset(
                      AssetPath().image('bg'),
                      width: Device.of(context).width,
                      height: Device.of(context).height,
                      fit: BoxFit.cover,
                      color: value,
                      colorBlendMode: BlendMode.multiply,
                    ),
                  );
                },
              ),
            ),
            SingleChildScrollView(
              child: Container(
                height: Device.of(context).height,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    WeatherInfo(
                      model: control.temperature,
                    ),
                    SizedBox(
                      height: 32.0,
                    ),
                    LoadingBuilder(
                      control: control.loading,
                      progress: (_) => progress(),
                      error: (_) => error(),
                      done: (_) => LocationInfo(
                        model: control.location,
                        onPlaceSelected: ui.showInput,
                        onLocationSelected: control.submitGps,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedBuilder(
              animation: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: ui.inputAnim, curve: Curves.ease)),
              builder: (context, child) => input(),
            ),
          ],
        ),
      ),
    );
  }

  Widget input() {
    final progress = ui.inputAnim?.value ?? 0.0;

    return Column(
      children: <Widget>[
        Visibility(
          visible: progress > 0.0,
          child: Expanded(
            child: GestureDetector(
              onTap: ui.hideInput,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12.0 * progress, sigmaY: 12.0 * progress),
                child: Container(
                  color: Colors.white10,
                ),
              ),
            ),
          ),
        ),
        Opacity(
          opacity: progress,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            width: Device.of(context).width,
            color: Colors.black45,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: InputField(
                    control: control.city,
                    cursorColor: Colors.white,
                    textAlign: TextAlign.center,
                  ),
                ),
                IconButton(
                  onPressed: () => control.submitCity(),
                  icon: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget error() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Text(
            control.loading.message ?? 'unknown error',
            style: Theme.of(context).textTheme.body1.copyWith(color: Colors.red),
          ),
          RaisedButton(
            onPressed: ui.showInput,
            child: Text('try again'),
          ),
        ],
      ),
    );
  }

  Widget progress() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class WeatherInfo extends StatelessWidget {
  final TemperatureModel model;

  const WeatherInfo({Key key, this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotifierBuilder<TemperatureModel>(
      control: model.state,
      builder: (context, model) {
        if (model.isAvailable) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                '${model.temperature.toInt()}°${model.unitSign}',
                style: Theme.of(context).textTheme.display1.copyWith(color: Colors.white),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                  ),
                  Text(
                    '${model.low.toInt()}°',
                    style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
                  ),
                  SizedBox(
                    width: 16.0,
                  ),
                  Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                  ),
                  Text(
                    '${model.high.toInt()}°',
                    style: Theme.of(context).textTheme.body2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ],
          );
        }

        return Text(
          'What\'s the weather ?',
          style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
        );
      },
    );
  }
}

class LocationInfo extends StatelessWidget {
  final LocationModel model;
  final VoidCallback onPlaceSelected;
  final VoidCallback onLocationSelected;

  const LocationInfo({
    Key key,
    @required this.model,
    this.onPlaceSelected,
    this.onLocationSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotifierBuilder<LocationModel>(
      control: model.state,
      builder: (context, model) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(
              height: 56.0,
              child: FlatButton(
                onPressed: onPlaceSelected,
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Stack(
                  children: <Widget>[
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          model.place ?? 'search',
                          style: Theme.of(context).textTheme.display2.copyWith(color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        onPressed: onPlaceSelected,
                        icon: Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 48.0,
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Stack(
                children: <Widget>[
                  Center(
                    child: Text(
                      model.isAvailable ? 'lat: ${model.lat}, lng: ${model.lng}' : 'check weather at your location ?',
                      style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      onPressed: onLocationSelected,
                      icon: Icon(
                        Icons.place,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
