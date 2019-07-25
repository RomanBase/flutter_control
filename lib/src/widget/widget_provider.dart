import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef RouteBuilder = Route Function(WidgetBuilder builder, RouteSettings settings);

/// Abstract implementation of simple widget initializer and holder.
abstract class WidgetInitializer {
  /// Current Widget.
  Widget _widget;

  WidgetInitializer();

  factory WidgetInitializer.of(WidgetBuilder builder) => _WidgetInitBuilder(builder);

  /// Widget initialization - typically called just once.
  /// Or when new initialization is forced.
  @protected
  Widget initWidget(BuildContext context, {Map args});

  /// Returns current Widget or tries to initialize new one.
  /// [forceInit] to re-init widget.
  Widget getWidget(BuildContext context, {forceInit: false, Map args}) => forceInit ? (_widget = initWidget(context, args: args)) : (_widget ?? (_widget = initWidget(context, args: args)));

  /// Returns context of initialized [ControlWidget]
  /// nullable
  BuildContext getContext() {
    if (_widget is ControlWidget) {
      return (_widget as ControlWidget).context;
    }

    return null;
  }

  WidgetBuilder wrap({Map args}) => (context) => getWidget(context, args: args);
}

/// Simple [WidgetBuilder] and holder.
class _WidgetInitBuilder extends WidgetInitializer {
  /// Current builder.
  final WidgetBuilder builder;

  /// Default constructor
  _WidgetInitBuilder(this.builder) {
    assert(builder != null);
  }

  @override
  Widget initWidget(BuildContext context, {Map args}) {
    final widget = builder(context);

    if (widget is Initializable) {
      (widget as Initializable).init(args);
    }

    return widget;
  }
}

class WidgetInit extends StatefulWidget {
  final Widget child;
  final Map<String, dynamic> args;

  const WidgetInit({Key key, this.child, this.args}) : super(key: key);

  @override
  _WidgetInitState createState() => _WidgetInitState();
}

class _WidgetInitState extends State<WidgetInit> {
  @override
  void initState() {
    super.initState();

    if (widget.child is Initializable) {
      (widget.child as Initializable).init(widget.args);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

//########################################################################################
//########################################################################################
//########################################################################################

/// Ties up [RouteNavigator] and [PageRouteProvider].
/// [PageRouteProvider.builder] is wrapped and Widget is initialized during build phase.
class RouteHandler {
  /// Implementation of navigator.
  final RouteNavigator navigator;

  /// Implementation of provider.
  final PageRouteProvider provider;

  /// Default constructor.
  /// [navigator] and [provider] must be specified.
  RouteHandler(this.navigator, this.provider) {
    assert(navigator != null);
    assert(provider != null);
  }

  /// [RouteNavigator.openRoute]
  Future<dynamic> openRoute({bool root: false, bool replacement: false, Map args}) {
    debugPrint("open route: ${provider.identifier} from $navigator");

    return navigator.openRoute(
      provider.getRoute(_initBuilder(provider.builder, args)),
      root: root,
      replacement: replacement,
    );
  }

  /// [RouteNavigator.openRoot]
  Future<dynamic> openRoot({Map args}) {
    debugPrint("open root: ${provider.identifier} from $navigator");

    return navigator.openRoot(
      provider.getRoute(_initBuilder(provider.builder, args)),
    );
  }

  /// [RouteNavigator.openDialog]
  Future<dynamic> openDialog({bool root: false, DialogType type, Map args}) {
    debugPrint("open dialog: ${provider.identifier} from $navigator");

    return navigator.openDialog(
      _initBuilder(provider.builder, args),
      root: root,
      type: type,
    );
  }

  /// Wraps [builder] and init widget during build phase.
  WidgetBuilder _initBuilder(WidgetBuilder builder, Map args) => WidgetInitializer.of(builder).wrap(args: args);
}

/// Abstract class for [PageRoute] construction with given settings.
class PageRouteProvider {
  /// Default [PageRoute] generator.
  factory PageRouteProvider.of({String identifier, String type, @required WidgetBuilder builder}) => PageRouteProvider()
    ..identifier = identifier
    ..type = type
    ..builder = builder;

  /// Route identifier [RouteSettings].
  String identifier;

  /// Route transition type.
  String type = Platform.operatingSystem;

  /// Page/Widget builder.
  WidgetBuilder builder;

  /// Default constructor.
  PageRouteProvider();

  /// Returns [PageRoute] of given type and with given settings.
  PageRoute getRoute(WidgetBuilder builder) {
    final settings = RouteSettings(name: identifier);

    if (type != null) {
      switch (type) {
        case 'android':
          return MaterialPageRoute(builder: builder, settings: settings);
        case 'ios':
          return CupertinoPageRoute(builder: builder, settings: settings);
      }
    }

    return MaterialPageRoute(builder: builder, settings: settings);
  }
}

//########################################################################################
//########################################################################################
//########################################################################################
