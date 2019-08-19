import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef RouteGetter = PageRoute Function(WidgetBuilder builder, RouteSettings settings);

/// Abstract class for basic type of navigation.
abstract class RouteNavigator {
  /// Pushes route into current Navigator.
  /// [route] - specific route: type, settings, transition etc.
  /// [root] - pushes route into root Navigator - onto top of everything.
  /// [replacement] - pushes route as replacement of current route.
  ///
  /// [Scaffold] as root context for [Navigator] is part of [BaseApp] Widget.
  /// As well [AppControl] can be initialized with custom root context and root Key.
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false});

  /// Clears current [Navigator] and opens new [Route].
  Future<dynamic> openRoot(Route route);

  /// Opens Dialog/ModalSheet/BottomSheet etc. as custom Widget Dialog via Controller.
  ///
  /// Scaffold as root context for [Navigator] is part of [BaseApp] Widget.
  /// As well [AppControl] can be initialized with custom root context and root Key.
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

/// Ties up [RouteNavigator] and [PageRouteProvider].
/// [PageRouteProvider.builder] is wrapped and Widget is initialized during build phase.
class RouteHandler {
  /// Implementation of navigator.
  final RouteNavigator navigator;

  /// Implementation of provider.
  final PageRouteProvider provider;

  Future<dynamic> result;

  PageRoute route;

  /// Default constructor.
  /// [navigator] and [provider] must be specified.
  RouteHandler(this.navigator, this.provider) {
    assert(navigator != null);
    assert(provider != null);
  }

  /// [RouteNavigator.openRoute]
  Future<dynamic> openRoute({bool root: false, bool replacement: false, Map<String, dynamic> args}) {
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

  /// [RouteNavigator.openRoot]
  Future<dynamic> openRoot({Map<String, dynamic> args}) {
    debugPrint("open root: ${provider.identifier} from $navigator");

    final initializer = WidgetInitializer.of(provider.builder);

    result = navigator.openRoot(
      route = provider.getRoute(initializer.wrap(args: args)),
    );

    initializer.data = route;

    return result;
  }

  /// [RouteNavigator.openDialog]
  Future<dynamic> openDialog({bool root: false, DialogType type, Map<String, dynamic> args}) {
    debugPrint("open dialog: ${provider.identifier} from $navigator");

    route = null;
    return result = navigator.openDialog(
      _initBuilder(provider.builder, args),
      root: root,
      type: type,
    );
  }

  /// Wraps [builder] and init widget during build phase.
  WidgetBuilder _initBuilder(WidgetBuilder builder, Map<String, dynamic> args) => WidgetInitializer.of(builder).wrap(args: args);
}

/// Abstract class for [PageRoute] construction with given settings.
class PageRouteProvider {
  /// Default [PageRoute] generator.
  factory PageRouteProvider.of({
    String identifier,
    dynamic type,
    @required WidgetBuilder builder,
    RouteGetter routeBuilder,
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
  RouteGetter routeBuilder;

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
  RouteHandler navigator(RouteNavigator navigator) => RouteHandler(navigator, this);
}
