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

  Future<dynamic> _result;

  Future<dynamic> get result => _result;

  Route _route;

  Route get route => _route;

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

    _result = navigator.openRoute(
      _route = provider.getRoute(initializer.wrap(args: args)),
      root: root,
      replacement: replacement,
    );

    initializer.data = _route;

    return _result;
  }

  /// [ControlNavigator.openRoot]
  Future<dynamic> openRoot({dynamic args}) {
    debugPrint("open root: ${provider.identifier} from $navigator");

    final initializer = WidgetInitializer.of(provider.builder);

    _result = navigator.openRoot(
      _route = provider.getRoute(initializer.wrap(args: args)),
    );

    initializer.data = _route;

    return _result;
  }

  /// [ControlNavigator.openDialog]
  Future<dynamic> openDialog({bool root: false, DialogType type, dynamic args}) {
    debugPrint("open dialog: ${provider.identifier} from $navigator");

    _route = null;
    return _result = navigator.openDialog(
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
  /// Default [Route] generator.
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

  factory PageRouteProvider.named(String identifier) => ControlProvider.get<RouteStorage>()?.getRoute(identifier);

  /// Route identifier [RouteSettings].
  String identifier;

  /// Route transition type.
  dynamic type = 'platform';

  /// Page/Widget builder.
  WidgetBuilder builder;

  /// Route builder.
  RouteBuilder routeBuilder;

  /// Default constructor.
  PageRouteProvider();

  /// Returns [Route] of given type and with given settings.
  Route getRoute(WidgetBuilder builder) {
    final settings = RouteSettings(name: identifier, arguments: type);

    if (routeBuilder != null) {
      return routeBuilder(builder, settings);
    }

    if (type == 'platform') {
      switch (Platform.operatingSystem) {
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

  void register() => ControlProvider.get<RouteStorage>()?.addProvider(this);
}

class RouteStorage {
  final _routes = Map<String, PageRouteProvider>();

  RouteStorage([List<PageRouteProvider> providers]) {
    if (providers != null) {
      addProviders(providers);
    }
  }

  void addProviders(List<PageRouteProvider> providers) {
    providers.forEach((item) => addProvider(item));
  }

  /// [identifier] is stored without '/' chars
  void addRoute(String identifier, Route route) {
    addProvider(
      PageRouteProvider()
        ..identifier = identifier
        ..routeBuilder = (_, __) => route,
    );
  }

  /// [identifier] is stored without '/' chars
  void addBuilder(String identifier, WidgetBuilder builder) {
    addProvider(PageRouteProvider.of(
      identifier: identifier,
      builder: builder,
    ));
  }

  /// [identifier] is stored without '/' chars
  void addProvider(PageRouteProvider provider) {
    final identifier = _identifier(provider.identifier);

    assert(() {
      if (_routes.containsKey(identifier)) {
        printDebug('Storage already contains key: $identifier. Route of this key will be overriden.');
      }
      return true;
    }());

    _routes[identifier] = provider;
  }

  /// Returns [PageRouteProvider] of given [identifier].
  PageRouteProvider getRoute(String identifier) {
    identifier = _identifier(identifier);

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    return null;
  }

  PageRouteProvider getRoot([String identifier]) {
    identifier = _identifier(identifier ?? '/');

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    return _routes.values.first;
  }

  /// removes all '/' chars
  String _identifier(String identifier) {
    assert(identifier != null);

    return identifier.replaceAll('/', '');
  }

  List<String> decompose(String identifier) {
    final list = List<String>();

    final items = identifier.split('/');

    if (identifier.startsWith('/')) {
      list.add('/');
    } else {
      list.add(items[0]);
    }

    if (items.length > 1) {
      for (int i = 1; i < items.length; i++) {
        list.add('${items[i - 1]}/${items[i]}');
      }
    }

    return list;
  }

  static List<PageRouteProvider> ofRoutes(Map<String, Route> routes) {
    final list = List<PageRouteProvider>();

    routes.forEach(
      (key, value) => PageRouteProvider()
        ..identifier = key
        ..routeBuilder = (_, __) => value,
    );

    return list;
  }

  static List<PageRouteProvider> ofBuilders(Map<String, WidgetBuilder> builders) {
    final list = List<PageRouteProvider>();

    builders.forEach(
      (key, value) => PageRouteProvider.of(
        identifier: key,
        builder: value,
      ),
    );

    return list;
  }
}
