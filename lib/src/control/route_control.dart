import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

typedef RouteWidgetBuilder = Route Function(
    WidgetBuilder builder, RouteSettings settings);

/// Providing basic type of navigation.
abstract class RouteNavigator {
  /// {@template route-open}
  /// Pushes route into current Navigator.
  /// [route] - specific route: type, settings, transition etc.
  /// [root] - pushes route into root Navigator - onto top of everything.
  /// [replacement] - pushes route as replacement of current route.
  /// {@endtemplate}
  Future<dynamic> openRoute(Route route,
      {bool root: false, bool replacement: false});

  /// {@template route-root}
  /// Clears current [Navigator] and opens new [Route].
  /// {@endtemplate}
  Future<dynamic> openRoot(Route route);

  /// {@template route-dialog}
  /// Opens specific dialog based on given [type]
  /// Be default opens simple pop-up dialog.
  /// {@endtemplate}
  Future<dynamic> openDialog(WidgetBuilder builder,
      {bool root: true, dynamic type});

  /// {@template route-back-root}
  /// Goes back in navigation stack until first [Route].
  /// {@endtemplate}
  void backToRoot();

  /// {@template route-back-to}
  /// Goes back in navigation stack until [Route] found.
  /// {@endtemplate}
  void backTo(
      {Route? route,
      String? identifier,
      bool Function(Route<dynamic>)? predicate});

  /// {@template route-close}
  /// Pops [Route] from navigation stack.
  /// result is send back to parent.
  /// {@endtemplate}
  bool close([dynamic result]);

  /// Removes given [route] from navigator.
  bool closeRoute(Route route, [dynamic result]);
}

/// Ties up [RouteNavigator] and [ControlRoute].
///
/// Initializes [Widget], builds [Route] with given properties and pushes this route to [Navigator].
/// Do not open multiple routes from one handler !
class RouteHandler {
  /// Implementation of navigator.
  final RouteNavigator? navigator;

  /// Implementation of provider.
  final ControlRoute routeProvider;

  /// Future of navigation result.
  Future<dynamic>? _result;

  /// Future of navigation result.
  /// This future is finished when Route is closed.
  Future<dynamic>? get result => _result;

  /// Current route.
  Route? _route;

  /// Actual [Route] build.
  Route? get route => _route;

  /// Checks if this handler did his job.
  /// Do not open multiple routes from one handler !
  bool get isHandled => _result != null;

  /// Route name. This identifier is typically stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  String? get identifier => routeProvider.identifier;

  /// Builds [Widget] and pushes [Route] to [Navigator].
  ///
  /// [navigator] - Implementation of [RouteNavigator] - typically [ControlWidget] with [RouteControl] mixin.
  /// [routeProvider] - Route settings and builder.
  ///
  /// Do not open multiple routes from one handler !
  RouteHandler(this.navigator, this.routeProvider) {
    assert(navigator != null,
        'Ensure that your widget implements [RouteNavigator] or is with [RouteControl] mixin.');
    assert(routeProvider != null);
  }

  /// Creates copy of [RouteHandler] with given builder.
  ///
  /// @{macro route-route}
  RouteHandler viaRoute(RouteWidgetBuilder builder) =>
      RouteHandler(navigator, routeProvider.viaRoute(builder));

  /// Creates copy of [RouteHandler] with given transition.
  ///
  /// @{macro route-transition}
  RouteHandler viaTransition(RouteTransitionsBuilder transition) =>
      RouteHandler(navigator, routeProvider.viaTransition(transition));

  /// Creates copy of [RouteHandler] with given path name.
  ///
  /// @{macro route-path}
  RouteHandler path(String path) =>
      RouteHandler(navigator, routeProvider.path(path));

  /// Creates copy of [RouteHandler] with given identifier.
  ///
  /// @{macro route-named}
  RouteHandler named(String identifier) =>
      RouteHandler(navigator, routeProvider.named(identifier));

  /// @{macro route-open}
  Future<dynamic>? openRoute(
      {bool root: false, bool replacement: false, dynamic args}) {
    printDebug("open route: ${routeProvider.identifier} from $navigator");

    _result = navigator!.openRoute(
      _route = routeProvider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result;
  }

  /// {@macro route-root}
  Future<dynamic>? openRoot({dynamic args}) {
    printDebug("open root: ${routeProvider.identifier} from $navigator");

    _result = navigator!.openRoot(_route = routeProvider.init(args: args));

    return _result;
  }

  /// @{macro route-dialog}
  Future<dynamic> openDialog({bool root: true, dynamic type, dynamic args}) {
    printDebug("open dialog: ${routeProvider.identifier} from $navigator");

    _route = null;
    return _result = navigator!.openDialog(
      WidgetInitializer.of(routeProvider._builder!).wrap(args: args),
      root: root,
      type: type,
    );
  }
}

/// [Route] builder with given settings.
/// Using [Type] as route identifier is recommended.
class ControlRoute {
  /// Builds [Route] via [builder] with given [identifier] and [settings].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  /// [settings] - Additional [Route] settings.
  ///
  /// Typically used with [Control.initControl] or [ControlRoot].
  /// ```
  ///   routes: [
  ///     ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
  ///     ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
  ///   ]
  /// ```
  /// Using [Type] as route identifier is recommended.
  static ControlRoute build<T>({
    dynamic identifier,
    dynamic settings,
    required WidgetBuilder builder,
  }) {
    assert(T != dynamic || identifier != null);

    return ControlRoute._()
      ..identifier = RouteStore.routeIdentifier<T>(identifier)
      ..settings = settings
      .._builder = builder;
  }

  /// Holds [Route] with given [identifier].
  /// Useful for specific or generated Routes.
  ///
  /// Check [RouteControl.build] for classic [WidgetBuilder] version.
  static ControlRoute route<T>({
    dynamic identifier,
    required Route route,
  }) =>
      ControlRoute._()
        ..identifier = RouteStore.routeIdentifier(identifier)
        .._routeBuilder = (_, __) => route;

  /// @{template route-store-get}
  /// Returns [ControlRoute] from [RouteStore] by given [Type] or [identifier].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  ///
  /// [RouteStore] is typically filled during [Control.initControl] or via [ControlRoot].
  /// [RouteStore] is also stored in [Control] -> [Control.get<RouteStore>()] and can be filled / updated anytime,
  ///
  /// Using [Type] as route identifier is recommended.
  /// @{endtemplate}
  static ControlRoute? of<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return Control.get<RouteStore>()?.getRoute<T>(identifier);
  }

  /// Returns identifier of Route stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  static String? identifierOf<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return Control.get<RouteStore>()?.getRoute<T>(identifier)?.identifier;
  }

  /// Route name. This identifier is typically stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  String? identifier;

  /// Additional route settings.
  /// By default is set to [Platform] - currently switching between [MaterialPageRoute] and [CupertinoPageRoute].
  dynamic settings = Platform;

  /// Required Widget builder.
  WidgetBuilder? _builder;

  /// Custom Route builder.
  RouteWidgetBuilder? _routeBuilder;

  /// Default private constructor.
  /// Use static constructors - [ControlRoute.build], [ControlRoute.route] or [ControlRoute.of].
  ControlRoute._();

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  Route _buildRoute(WidgetBuilder builder) {
    final routeSettings = RouteSettings(name: identifier, arguments: settings);

    if (_routeBuilder != null) {
      return _routeBuilder!(builder, routeSettings);
    }

    if (settings == Platform) {
      switch (Platform.operatingSystem) {
        case 'android':
          return MaterialPageRoute(builder: builder, settings: routeSettings);
        case 'ios':
          return CupertinoPageRoute(builder: builder, settings: routeSettings);
      }
    }

    return MaterialPageRoute(builder: builder, settings: routeSettings);
  }

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  /// Given [args] are passed to Widget.
  Route init({dynamic args}) {
    final initializer = WidgetInitializer.of(_builder!);

    final route = _buildRoute(initializer.wrap(args: args));

    initializer.data = route;

    return route;
  }

  /// {@template route-route}
  /// Setups new [routeBuilder] and returns copy of [ControlRoute] with new settings..
  /// {@endtemplate}
  ControlRoute viaRoute(RouteWidgetBuilder routeBuilder) =>
      _copyWith(routeBuilder: routeBuilder);

  /// {@macro route-route}
  /// Via [MaterialPageRoute].
  ControlRoute viaMaterialRoute() => viaRoute((builder, settings) =>
      MaterialPageRoute(builder: builder, settings: settings));

  /// {@macro route-route}
  /// Via [CupertinoPageRoute].
  ControlRoute viaCupertinoRoute() => viaRoute((builder, settings) =>
      CupertinoPageRoute(builder: builder, settings: settings));

  /// {@template route-transition}
  /// Setups new [transition] with given [duration] and returns copy of [ControlRoute] with new settings..
  /// [ControlRouteTransition] is used as [PageRoute].
  /// {@endtemplate}
  ControlRoute viaTransition(RouteTransitionsBuilder transition,
          [Duration duration = const Duration(milliseconds: 300)]) =>
      _copyWith(
          routeBuilder: (builder, settings) => ControlRouteTransition(
                builder: builder,
                transition: transition,
                duration: duration,
                settings: settings,
              ));

  /// {@template route-path}
  /// Alters current [identifier] with given [path] and returns copy of [ControlRoute] with new settings.
  /// ```
  /// ControlRoute.of<DetailPage>().path('/detail/123');
  /// ```
  /// {@endtemplate}
  ControlRoute path(String path) => _copyWith(
      identifier:
          RouteStore.routePathIdentifier(identifier: identifier, path: path));

  /// {@template route-name}
  /// Changes current [identifier] and returns copy of [ControlRoute] with new settings..
  /// {@endtemplate}
  ControlRoute named(String identifier) => _copyWith(identifier: identifier);

  /// Creates copy of [RouteControl] with given settings.
  ControlRoute _copyWith(
          {dynamic identifier,
          dynamic settings,
          RouteWidgetBuilder? routeBuilder}) =>
      ControlRoute._()
        ..identifier = identifier ?? this.identifier
        ..settings = settings ?? this.settings
        .._builder = _builder
        .._routeBuilder = routeBuilder ?? this._routeBuilder;

  /// Initializes [RouteHandler] with given [navigator] and this Route provider.
  RouteHandler navigator(RouteNavigator? navigator) =>
      RouteHandler(navigator, this);

  /// Registers this Route to [RouteStore].
  void register<T>() => Control.get<RouteStore>()?.addRoute<T>(this);
}

/// Custom [PageRoute] building Widget via given [RouteTransitionsBuilder].
class ControlRouteTransition extends PageRoute {
  /// Builder of Widget.
  final WidgetBuilder builder;

  /// Builder of Transition.
  final RouteTransitionsBuilder transition;

  /// Duration of transition Animation.
  final Duration duration;

  /// Simple [PageRoute] with custom [transition].
  ControlRouteTransition({
    required this.builder,
    required this.transition,
    this.duration: const Duration(milliseconds: 300),
    RouteSettings? settings,
  }) : super(settings: settings);

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation) =>
      builder(context);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      transition(context, animation, secondaryAnimation, child);

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;
}

/// Stores [ControlRoute] by identifier key - [RouteStore.routeIdentifier].
/// Instance of [RouteStore] is stored in [ControlFactory] -> 'Control.get<RouteStore>()'.
///
/// Typically not used directly, but via framework:
///   - fill routes: [Control.initControl] or add routes directly.
///   - retrieve route: [ControlRoute.of].
class RouteStore {
  /// Map based Route Store.
  /// Key: [RouteStore.routeIdentifier].
  /// Value: [RouteControl].
  final _routes = Map<String?, ControlRoute>();

  /// Stores Routes with their Identifiers.
  ///
  /// Typically not used directly, but via framework:
  ///   - fill: [Control.initControl] or [ControlRoute] routes property.
  ///   - retrieve route: [ControlRoute.of].
  RouteStore([List<ControlRoute>? routes]) {
    if (routes != null) {
      addRoutes(routes);
    }
  }

  /// Adds [ControlRoute] one by one to [RouteStore].
  void addRoutes(List<ControlRoute> routes) {
    routes.forEach((item) => addRoute(item));
  }

  /// Creates [ControlRoute] from given [builder] and adds it to [RouteStore].
  /// Returns store key.
  String? addRawRoute<T>({dynamic identifier, required Route route}) {
    return addRoute<T>(ControlRoute.route<T>(
      identifier: identifier,
      route: route,
    ));
  }

  /// Creates [ControlRoute] from given [builder] and adds it to [RouteStore].
  /// Returns store key.
  String? addBuilder<T>({dynamic identifier, required WidgetBuilder builder}) {
    return addRoute<T>(ControlRoute.build<T>(
      identifier: identifier,
      builder: builder,
    ));
  }

  /// Adds given [route] to [RouteStore].
  /// Returns store key.
  String? addRoute<T>(ControlRoute route) {
    final identifier = route.identifier ?? routeIdentifier<T>();

    assert(() {
      if (_routes.containsKey(identifier)) {
        printDebug(
            'Storage already contains key: $identifier. Route of this key will be overriden.');
      }
      return true;
    }());

    _routes[identifier] = route;

    return identifier;
  }

  /// Returns [ControlRoute] of given [Type] or [identifier] - check [RouteStore.routeIdentifier] for more info about Store keys.
  ///
  /// Using [Type] as route key is recommended.
  ControlRoute? getRoute<T>([dynamic identifier]) {
    identifier = routeIdentifier<T>(identifier);

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    return null;
  }

  /// Decompose given [identifier] and splits path to separated parts.
  /// Currently usable just for debug purposes.
  /// Returns parts of path in [List].
  List<String> decompose(String identifier) {
    final list = <String>[];

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

  /// Resolves identifier for given route [Type] and [name].
  /// Similar to [ControlFactory.keyOf], but also accepts [String] as valid [value] key.
  /// This method is mainly used by framework to determine identifier of [ControlRoute] stored in [RouteStore].
  ///
  /// Returned identifier is formatted as path -> '/name'.
  static String? routeIdentifier<T>([dynamic value]) {
    if (value == null && T != dynamic) {
      value = T;
    }

    String? id;

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

  /// Alters given [identifier] with [path].
  static String routePathIdentifier<T>({dynamic identifier, required String path}) {
    if (!path.startsWith('/')) {
      path = '/$path';
    }

    return routeIdentifier(identifier)! + path;
  }
}
