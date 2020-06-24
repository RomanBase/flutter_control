import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef RouteWidgetBuilder = Route Function(WidgetBuilder builder, RouteSettings settings);

/// Abstract class for basic type of navigation.
abstract class RouteNavigator {
  /// Pushes route into current Navigator.
  /// [route] - specific route: type, settings, transition etc.
  /// [root] - pushes route into root Navigator - onto top of everything.
  /// [replacement] - pushes route as replacement of current route.
  Future<dynamic> openRoute(Route route, {bool root: false, bool replacement: false});

  /// Clears current [Navigator] and opens new [Route].
  Future<dynamic> openRoot(Route route);

  Future<dynamic> openDialog(WidgetBuilder builder, {bool root: true, dynamic type});

  /// Goes back in navigation stack until first [Route].
  void backToRoot();

  /// Goes back in navigation stack until [Route] found.
  void backTo({Route route, String identifier, bool Function(Route<dynamic>) predicate});

  /// Pops [Route] from navigation stack.
  /// result is send back to parent.
  bool close([dynamic result]);

  /// Removes given [route] from navigator.
  bool closeRoute(Route route, [dynamic result]);
}

/// Ties up [RouteNavigator] and [ControlRoute].
/// [ControlRoute.builder] is wrapped and Widget is initialized during build phase.
class RouteHandler {
  /// Implementation of navigator.
  final RouteNavigator navigator;

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

  RouteHandler viaRoute(RouteWidgetBuilder route) => RouteHandler(navigator, provider.viaRoute(route));

  RouteHandler viaTransition(RouteTransitionsBuilder transition) => RouteHandler(navigator, provider.viaTransition(transition));

  RouteHandler path(String path) => RouteHandler(navigator, provider.path(path));

  RouteHandler named(String identifier) => RouteHandler(navigator, provider.named(identifier));

  /// [RouteNavigator.openRoute]
  Future<dynamic> openRoute({bool root: false, bool replacement: false, dynamic args}) {
    printDebug("open route: ${provider.identifier} from $navigator");

    _result = navigator.openRoute(
      _route = provider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result;
  }

  /// [RouteNavigator.openRoot]
  Future<dynamic> openRoot({dynamic args}) {
    printDebug("open root: ${provider.identifier} from $navigator");

    _result = navigator.openRoot(provider.init(args: args));

    return _result;
  }

  /// [RouteNavigator.openDialog]
  Future<dynamic> openDialog({bool root: true, dynamic type, dynamic args}) {
    printDebug("open dialog: ${provider.identifier} from $navigator");

    _route = null;
    return _result = navigator.openDialog(
      WidgetInitializer.of(provider.builder).wrap(args: args),
      root: root,
      type: type,
    );
  }
}

/// Abstract class for [PageRoute] construction with given settings.
class ControlRoute {
  /// Default [Route] generator.
  static ControlRoute build<T>({
    dynamic identifier,
    dynamic settings,
    @required WidgetBuilder builder,
  }) =>
      ControlRoute()
        ..identifier = RouteStore.routeIdentifier<T>(identifier)
        ..settings = settings
        ..builder = builder;

  static ControlRoute route<T>({
    dynamic identifier,
    @required Route route,
  }) =>
      ControlRoute()
        ..identifier = RouteStore.routeIdentifier(identifier)
        ..routeBuilder = (_, __) => route;

  /// @{template route-store-get}
  ///
  /// @{endtemplate}
  static ControlRoute of<T>([dynamic identifier]) => Control.get<RouteStore>()?.getRoute<T>(identifier);

  String identifier;

  /// Route transition type.
  dynamic settings = 'platform';

  /// Widget builder.
  WidgetBuilder builder;

  /// Route builder.
  RouteWidgetBuilder routeBuilder;

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

  Route init({dynamic args}) {
    final initializer = WidgetInitializer.of(builder);

    final route = buildRoute(initializer.wrap(args: args));

    initializer.data = route;

    return route;
  }

  ControlRoute viaRoute(RouteWidgetBuilder route) => _copyWith(routeBuilder: route);

  ControlRoute viaTransition(RouteTransitionsBuilder transition, [Duration duration = const Duration(milliseconds: 300)]) => _copyWith(
      routeBuilder: (builder, settings) => ControlRouteTransition(
            builder: builder,
            transition: transition,
            duration: duration,
            settings: settings,
          ));

  ControlRoute path(String path) => _copyWith(identifier: '$identifier$path');

  ControlRoute named(String identifier) => _copyWith(identifier: identifier);

  ControlRoute _copyWith({dynamic identifier, dynamic settings, RouteWidgetBuilder routeBuilder}) => ControlRoute()
    ..identifier = identifier ?? this.identifier
    ..settings = settings ?? this.settings
    ..builder = builder
    ..routeBuilder = routeBuilder ?? this.routeBuilder;

  /// Initializes [RouteHandler] with given [navigator] and this route provider.
  RouteHandler navigator(RouteNavigator navigator) => RouteHandler(navigator, this);

  void register<T>() => Control.get<RouteStore>()?.addProvider<T>(this);
}

class ControlRouteTransition extends PageRoute {
  final WidgetBuilder builder;
  final RouteTransitionsBuilder transition;
  final Duration duration;

  ControlRouteTransition({
    @required this.builder,
    @required this.transition,
    this.duration: const Duration(milliseconds: 300),
    RouteSettings settings,
  }) : super(settings: settings);

  @override
  Color get barrierColor => null;

  @override
  String get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) => builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) => transition(context, animation, secondaryAnimation, child);

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;
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
