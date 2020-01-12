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

/// Ties up [ControlNavigator] and [ControlRoute].
/// [ControlRoute.builder] is wrapped and Widget is initialized during build phase.
class RouteHandler {
  /// Implementation of navigator.
  final ControlNavigator navigator;

  /// Implementation of provider.
  final ControlRoute provider;

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
      _route = provider.buildRoute(initializer.wrap(args: args)),
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
      _route = provider.buildRoute(initializer.wrap(args: args)),
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
class ControlRoute {
  /// Default [Route] generator.
  static ControlRoute build<T>({
    dynamic identifier,
    dynamic settings,
    @required WidgetBuilder builder,
    RouteBuilder routeBuilder,
  }) =>
      ControlRoute()
        ..identifier = RouteStore.routeIdentifier<T>(identifier)
        ..settings = settings
        ..builder = builder
        ..routeBuilder = routeBuilder;

  static ControlRoute route<T>({
    dynamic identifier,
    @required Route route,
  }) =>
      ControlRoute()
        ..identifier = RouteStore.routeIdentifier(identifier)
        ..routeBuilder = (_, __) => route;

  static ControlRoute of<T>([dynamic identifier]) => Control.get<RouteStore>()?.getRoute<T>(identifier);

  String identifier;

  /// Route transition type.
  dynamic settings = 'platform';

  /// Widget builder.
  WidgetBuilder builder;

  /// Route builder.
  RouteBuilder routeBuilder;

  /// Default constructor.
  ControlRoute();

  /// Returns [Route] of given type and with given settings.
  Route buildRoute(WidgetBuilder builder) {
    final routeSettings = RouteSettings(name: identifier, arguments: settings);

    if (routeBuilder != null) {
      return routeBuilder(builder, routeSettings);
    }

    if (settings == 'platform') {
      switch (Platform.operatingSystem) {
        case 'android':
          return MaterialPageRoute(builder: builder, settings: routeSettings);
        case 'ios':
          return CupertinoPageRoute(builder: builder, settings: routeSettings);
      }
    }

    return MaterialPageRoute(builder: builder, settings: routeSettings);
  }

  /// Initializes [RouteHandler] with given [navigator] and this route provider.
  RouteHandler navigator(ControlNavigator navigator) => RouteHandler(navigator, this);

  void register<T>() => Control.get<RouteStore>()?.addProvider<T>(this);
}

class RouteStore {
  final _routes = Map<String, ControlRoute>();

  RouteStore([List<ControlRoute> providers]) {
    if (providers != null) {
      addProviders(providers);
    }
  }

  void addProviders(List<ControlRoute> providers) {
    providers.forEach((item) => addProvider(item));
  }

  String addRoute<T>({dynamic identifier, @required Route route}) {
    return addProvider<T>(ControlRoute.route<T>(
      identifier: identifier,
      route: route,
    ));
  }

  String addBuilder<T>({dynamic identifier, @required WidgetBuilder builder}) {
    return addProvider<T>(ControlRoute.build<T>(
      identifier: identifier,
      builder: builder,
    ));
  }

  String addProvider<T>(ControlRoute provider) {
    final identifier = provider.identifier ?? routeIdentifier<T>();

    assert(() {
      if (_routes.containsKey(identifier)) {
        printDebug('Storage already contains key: $identifier. Route of this key will be overriden.');
      }
      return true;
    }());

    _routes[identifier] = provider;

    return identifier;
  }

  /// Returns [ControlRoute] of given [identifier].
  ControlRoute getRoute<T>([dynamic identifier]) {
    identifier = routeIdentifier<T>(identifier);

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    return null;
  }

  ControlRoute getRoot([String identifier]) {
    identifier ??= '/';

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    return _routes.values.first;
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

  static String routeIdentifier<T>([dynamic value]) {
    if (value == null && T != dynamic) {
      value = T;
    }

    String id;

    if (value is String) {
      id = value;
    } else if (value is Type) {
      id = value.toString();
    } else if (value != null) {
      id = value.runtimeType.toString();
    }

    if (id != null && !id.startsWith('/')) {
      id = '/$id';
    }

    return id;
  }
}
