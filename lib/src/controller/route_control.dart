import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef RouteBuilder = PageRoute Function(WidgetBuilder builder, RouteSettings settings);

//TODO: documentation is old and don't match now..
/// Abstract class for basic type of navigation.
abstract class ControlNavigator {
  /// Pushes route into current Navigator.
  /// [route] - specific route: type, settings, transition etc.
  /// [root] - pushes route into root Navigator - onto top of everything.
  /// [replacement] - pushes route as replacement of current route.
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false});

  /// Clears current [Navigator] and opens new [Route].
  Future<dynamic> openRoot(Route route);

  /// Opens Dialog/ModalSheet/BottomSheet etc. as custom Widget Dialog via Controller.
  Future<dynamic> openDialog(WidgetBuilder builder, {bool root: false, DialogType type: DialogType.popup});

  /// Goes back in navigation stack until first [Route].
  void backToRoot();

  /// Goes back in navigation stack until [Route] found.
  void backTo({Route route, String identifier, bool Function(Route<dynamic>) predicate});

  /// Pops [Route] from navigation stack.
  /// result is send back to parent.
  void close([dynamic result]);

  /// Removes given [route] from navigator.
  void closeRoute(Route route, [dynamic result]);
}

/// Ties up [ControlNavigator] and [PageRouteProvider].
/// [PageRouteProvider.builder] is wrapped and Widget is initialized during build phase.
class RouteHandler {
  /// Implementation of navigator.
  final ControlNavigator navigator;

  /// Implementation of provider.
  final PageRouteProvider provider;

  Future<dynamic> result;

  PageRoute route;

  /// Default constructor.
  /// [navigator] and [provider] must be specified.
  RouteHandler(this.navigator, this.provider) {
    assert(navigator != null, 'Ensure that your widget implements [ControlNavigator] or is with [RouteNavigator] mixin.');
    assert(provider != null);
  }

  /// [ControlNavigator.openRoute]
  Future<dynamic> openRoute({bool root: false, bool replacement: false, dynamic args}) {
    debugPrint("open route: ${provider.identifier} from $navigator");

    final initializer = WidgetInitializer.of(provider.builder);

    result = navigator.openRoute(
      route = provider.getRoute(initializer.wrap(args: args)),
      root: root,
      replacement: replacement,
    );

    initializer.data = route;

    return result;
  }

  /// [ControlNavigator.openRoot]
  Future<dynamic> openRoot({dynamic args}) {
    debugPrint("open root: ${provider.identifier} from $navigator");

    final initializer = WidgetInitializer.of(provider.builder);

    result = navigator.openRoot(
      route = provider.getRoute(initializer.wrap(args: args)),
    );

    initializer.data = route;

    return result;
  }

  /// [ControlNavigator.openDialog]
  Future<dynamic> openDialog({bool root: false, DialogType type, dynamic args}) {
    debugPrint("open dialog: ${provider.identifier} from $navigator");

    route = null;
    return result = navigator.openDialog(
      _initBuilder(provider.builder, args),
      root: root,
      type: type,
    );
  }

  /// Wraps [builder] and init widget during build phase.
  WidgetBuilder _initBuilder(WidgetBuilder builder, dynamic args) => WidgetInitializer.of(builder).wrap(args: args);
}

/// Abstract class for [PageRoute] construction with given settings.
class PageRouteProvider {
  /// Default [PageRoute] generator.
  factory PageRouteProvider.of({
    String identifier,
    dynamic type,
    @required WidgetBuilder builder,
    RouteBuilder routeBuilder,
  }) =>
      PageRouteProvider()
        ..identifier = identifier
        ..type = type
        ..builder = builder
        ..routeBuilder = routeBuilder;

  /// Route identifier [RouteSettings].
  String identifier;

  /// Route transition type.
  dynamic type = Platform.operatingSystem;

  /// Page/Widget builder.
  WidgetBuilder builder;

  /// Route builder.
  RouteBuilder routeBuilder;

  /// Default constructor.
  PageRouteProvider();

  /// Returns [PageRoute] of given type and with given settings.
  PageRoute getRoute(WidgetBuilder builder) {
    final settings = RouteSettings(name: identifier, arguments: type);

    if (routeBuilder != null) {
      return routeBuilder(builder, settings);
    }

    if (type != null && type is String) {
      switch (type) {
        case 'android':
          return MaterialPageRoute(builder: builder, settings: settings);
        case 'ios':
          return CupertinoPageRoute(builder: builder, settings: settings);
      }
    }

    return MaterialPageRoute(builder: builder, settings: settings);
  }

  /// Initializes [RouteHandler] with given [navigator] and this route provider.
  RouteHandler navigator(ControlNavigator navigator) => RouteHandler(navigator, this);
}
