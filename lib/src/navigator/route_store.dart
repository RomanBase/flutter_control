part of flutter_control;

/// An abstract provider for a list of [ControlRoute]s.
abstract class RoutingStoreProvider {
  /// The list of routes provided.
  List<ControlRoute> get routes;

  RoutingStoreProvider();

  /// Creates a [RoutingStoreProvider] from a list of routes and other providers.
  factory RoutingStoreProvider.of(
          {List<ControlRoute> routes = const [],
          List<RoutingStoreProvider> providers = const []}) =>
      _RoutingStoreProvider(
        [
          ...routes,
          ...providers.map((e) => e.routes).fold([], (a, b) => [...a, ...b]),
        ],
      );
}

class _RoutingStoreProvider extends RoutingStoreProvider {
  @override
  final List<ControlRoute> routes;

  _RoutingStoreProvider(this.routes);
}

/// A [ControlModule] for initializing and providing a [RouteStore].
class RoutingModule extends ControlModule<RouteStore> {
  /// The initial list of routes for the store.
  final List<ControlRoute> routes;

  @override
  Map<Type, InitFactory> get factories => {
        RoutingProvider: (_) => module?.routing,
      };

  RoutingModule(this.routes) {
    initModule();
  }

  void initModule() {
    super.initModule();

    if (!isInitialized) {
      module = RouteStore(routes);
    }
  }

  @override
  Future init() async {}
}

/// A specialized version of [ControlArgs] for route handling.
/// It contains the [ControlRoute], [RouteMask], and any passed arguments.
class RouteArgs extends ControlArgs {
  /// The route definition.
  ControlRoute get route => get<ControlRoute>()!;

  /// The path mask for the route.
  RouteMask get mask => get<RouteMask>()!;

  RouteArgs._(ControlRoute route, RouteMask mask, [dynamic args])
      : super(ControlArgs.of(args).data) {
    add(value: route);
    add(value: mask);
  }

  /// Formats the route's path with the given [args].
  String format(dynamic args, [ParseDecoratorFormat? decorator]) =>
      mask.format(args, decorator);
}

/// Stores [ControlRoute] definitions, mapping them by a unique identifier.
///
/// This class acts as a central repository for all registered routes in the application.
/// An instance of [RouteStore] is typically registered with the global [ControlFactory].
///
/// Routes are usually added at app startup and then retrieved using [ControlRoute.of].
class RouteStore {
  /// The routing provider for generating routes.
  late RoutingProvider routing = RoutingProvider._(this);

  /// The internal map holding the route definitions.
  /// Key: A unique route identifier, see [RouteStore.routeIdentifier].
  /// Value: The [ControlRoute] definition.
  final _routes = Map<String, ControlRoute>();

  /// A list of path masks for efficient route matching.
  final _masks = <RouteMask>[];

  /// Creates a [RouteStore], optionally initializing it with a list of [routes].
  RouteStore([List<ControlRoute>? routes]) {
    if (routes != null) {
      addRoutes(routes);
    }
  }

  /// Adds a list of [ControlRoute]s to the store.
  void addRoutes(List<ControlRoute> routes) {
    routes.forEach((item) => addRoute(item));
  }

  /// Adds a single [route] to the store.
  /// Overwrites an existing route if the identifier is the same.
  /// Returns the identifier used to store the route.
  String? addRoute<T>(ControlRoute route) {
    final identifier = route.identifier;

    assert(() {
      if (_routes.containsKey(identifier)) {
        printDebug(
            'Storage already contains key: $identifier. Route of this key will be override.');
      }
      return true;
    }());

    _routes[identifier] = route;
    _masks.add(RouteMask.of(route._mask ?? identifier, identifier));

    return identifier;
  }

  /// Retrieves a [ControlRoute] from the store.
  ///
  /// The route can be identified by its [Type] or a custom string [identifier].
  /// Using a [Type] is recommended for type safety.
  ControlRoute? getRoute<T>([dynamic identifier]) {
    identifier = routeIdentifier<T>(identifier);

    if (_routes.containsKey(identifier)) {
      return _routes[identifier];
    }

    identifier = RouteMask.of(identifier);
    final mask = _masks.firstWhere((element) => element.match(identifier),
        orElse: () => RouteMask.empty);

    if (mask.isNotEmpty && _routes.containsKey(mask.identifier)) {
      return _routes[mask.identifier];
    }

    return null;
  }

  /// Resolves a unique identifier for a route.
  ///
  /// This method is used by the framework to create a consistent key for storing
  /// and retrieving routes in the [RouteStore].
  ///
  /// The identifier is formatted as a path (e.g., '/HomePage').
  static String routeIdentifier<T>([dynamic value]) {
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

    String key = id ?? UnitId.nextId();

    if (!key.startsWith('/')) {
      key = '/$key';
    }

    return key;
  }

  static RouteMask routePathMask(String path) => RouteMask.of(path);

  /// Builds a full route path with path segments and query parameters.
  static String routePathIdentifier<T>(
      {dynamic identifier, dynamic path, dynamic args}) {
    if (path == null) {
      path = routeIdentifier(identifier);
    } else if (path is String) {
      if (!path.startsWith('/')) {
        path = '/$path';
      }
    } else if (path is List) {
      path = '/' + path.join('/');
    } else if (path is Map) {
      path = '/' +
          Parse.toList(args, entryConverter: (key, value) => '$key/$value')
              .join('/');
    }

    if (args == null || (args is String && args.isEmpty)) {
      return path;
    }

    if (args is Map) {
      return '$path?' +
          Parse.toList(args, entryConverter: (key, value) => '$key=$value')
              .join('&');
    }

    if (args is List) {
      return '$path?args=' + args.join(',');
    }

    if (path.endsWith('/')) {
      return '$path$args';
    }

    return '$path/$args';
  }
}

class RouteMask {
  final List<_PathSegment> _segments;

  final String identifier;

  String get path => '/' + _segments.map((e) => e.name).join('/');

  List<String> get args =>
      _segments.where((e) => e.mask).map((e) => e.name).toList();

  bool get isEmpty => _segments.isEmpty;

  bool get isNotEmpty => _segments.isNotEmpty;

  int get segmentCount => _segments.length;

  static RouteMask get root =>
      RouteMask._([_PathSegment('', false, null)], '/');

  static RouteMask get empty => RouteMask._([], '/');

  const RouteMask._(this._segments, this.identifier);

  factory RouteMask.of(String? path, [String? identifier]) => path == null
      ? empty
      : (path == '/'
          ? root
          : RouteMask._(
              _PathSegment.chain(Uri.parse(path, 0,
                      path.endsWith('/') ? path.length - 1 : path.length)
                  .pathSegments),
              identifier ?? path));

  bool match(RouteMask other) {
    if (other._segments.length != _segments.length) {
      return false;
    }

    for (int i = 0; i < _segments.length; i++) {
      if (_segments[i].mask) {
        continue;
      }

      if (_segments[i].name != other._segments[i].name) {
        return false;
      }
    }

    return true;
  }

  String format(dynamic args, [ParseDecoratorFormat? decorator]) {
    if (args == null || this.args.isEmpty) {
      return path;
    }

    if (args is Iterable) {
      _PathSegment? _segment = _segments.first.firstMask();
      final map = <String, String>{};

      for (int i = 0; i < args.length; i++) {
        if (_segment == null) {
          break;
        }

        map[_segment.name] = args.elementAt(i);
        _segment = _segment.nextMask();
      }

      return Parse.format(path, map, ParseDecorator.none);
    }

    if (args is Map) {
      return Parse.format(
          path,
          Parse.toMap(args,
              key: (key, value) => '$key', converter: (value) => '$value'),
          decorator);
    }

    return Parse.format(path, {this.args.first: '$args'}, ParseDecorator.none);
  }

  Map<String, dynamic> params(RouteMask other,
      [int decoratorStartOffset = 1, int decoratorEndOffset = 1]) {
    final map = <String, dynamic>{};

    RouteMask mask;
    RouteMask route;

    if (args.isEmpty) {
      if (other.args.isEmpty) {
        return {};
      }

      mask = other;
      route = this;
    } else {
      mask = this;
      route = other;
    }

    final count = mask.segmentCount;
    for (int i = 0; i < count; i++) {
      if (mask._segments[i].mask && route.segmentCount > i) {
        map[mask._segments[i]
                .substringName(decoratorStartOffset, decoratorEndOffset)] =
            route._segments[i].name;
      }
    }

    if (route.identifier.contains('?')) {
      final args = route.identifier.split('?')[1];

      args.split('&').forEach((value) {
        final arg = value.split('=');
        map[arg[0]] = arg[1];
      });
    }

    return map;
  }
}

class _PathSegment {
  static RegExp _mask = RegExp('{.*}');

  final String name;
  final bool mask;
  final _PathSegment? next;

  _PathSegment(this.name, this.mask, this.next);

  static List<_PathSegment> chain(List<String> parts) {
    final segments = <_PathSegment>[];

    _PathSegment? lastSegment;
    parts.reversed.forEach((element) {
      segments.add(lastSegment = _PathSegment(
        element,
        _mask.hasMatch(element),
        lastSegment,
      ));
    });

    return segments.reversed.toList();
  }

  String substringName(int startOffset, int endOffset) =>
      name.substring(startOffset, name.length - endOffset);

  _PathSegment? firstMask() {
    if (mask) {
      return this;
    }

    return nextMask();
  }

  _PathSegment? nextMask() {
    if (next != null) {
      return next!.firstMask();
    }

    return null;
  }
}

/// Provides route generation logic, typically used with `onGenerateRoute`.
class RoutingProvider {
  /// The parent [RouteStore] containing all route definitions.
  final RouteStore parent;

  /// A callback to handle route generation.
  RouteFactory? onGenerate;

  RoutingProvider._(this.parent);

  /// Retrieves [RouteSettings] that were stored during a previous navigation attempt
  /// (e.g., when the app was launched from a deep link before initialization).
  RouteSettings? popSettings(BuildContext context) =>
      (context is RootContext ? context : context.root)
          .args
          .pop<RouteSettings>();

  /// Generates a [Route] based on the provided [settings].
  /// This is the core logic for `onGenerateRoute`.
  Route? generate(BuildContext context, RouteSettings settings,
      {bool? active, RouteFactory? onGenerate}) {
    if (onGenerate != null) {
      this.onGenerate = onGenerate;
    }

    final root = context is RootContext ? context : context.root;

    String? path = settings.name;

    if (path == null) {
      return null;
    }

    active ??= Control.isInitialized;

    if (!active) {
      if (settings.name != '/') {
        root.set(value: settings);
      }

      return null;
    }

    final args = ControlArgs.of(settings.arguments);

    final controlRoute = parent.getRoute(path);

    if (controlRoute != null) {
      final mask = RouteMask.of(controlRoute._mask ?? controlRoute.identifier);
      final params = mask.params(RouteMask.of(path));

      args.add(value: controlRoute);
      args.add(value: mask);
      params.forEach((key, value) => args.add(key: key, value: value));
    }

    if (this.onGenerate == null) {
      return controlRoute
          ?._copyWith(
            identifier: path,
          )
          .init(args: args.data);
    }

    return this.onGenerate?.call(RouteSettings(
          name: path,
          arguments: args.data,
        ));
  }

  /// Restores a route from previously popped settings.
  Route? restore(BuildContext context) {
    final settings = popSettings(context);

    if (settings != null) {
      return generate(context, settings);
    }

    return null;
  }

  List<Route> restoreAll(BuildContext context, List<dynamic> subRoutes) {
    final store = Control.get<RouteStore>()!;
    final settings = store.routing.popSettings(context);

    final output = <Route>[];

    if (settings == null) {
      return output;
    }

    final route = store.routing.generate(context, settings);

    if (route == null) {
      return output;
    }

    for (final sub in subRoutes) {
      final subMask = store.getRoute(sub)?.mask;

      if (subMask == null) {
        continue;
      }

      if (!subMask.match(RouteMask.of(route.settings.name))) {
        final path =
            subMask.format(ControlArgs.of(route.settings.arguments).data);

        final subRoute =
            store.routing.generate(context, RouteSettings(name: path));

        if (subRoute != null) {
          output.add(subRoute);
        }
      }
    }

    output.add(route);

    return output;
  }

  /// Restores and navigates to a route from previously stored settings.
  Future<dynamic> restoreRouteNavigation(
      BuildContext context, RouteNavigator navigator,
      [List<dynamic> subRoutes = const []]) async {
    if (subRoutes.isEmpty) {
      final route = restore(context);

      if (route != null) {
        return navigator.openRoute(route);
      }
    } else {
      final routes = restoreAll(context, subRoutes);

      for (final route in routes) {
        navigator.openRoute(route);
      }
    }

    return null;
  }
}

/// Extension on [RootContext] for routing.
extension RootContextRouterExt on RootContext {
  /// Generates a route, with a special case for the root ('/') route.
  Route? generateRoute(RouteSettings settings, {Route Function()? root}) =>
      (settings.name == '/' && root != null)
          ? root.call()
          : Control.get<RouteStore>()?.routing.generate(this, settings);
}

/// Extension on [CoreContext] for routing.
extension BuildContextRouterExt on CoreContext {
  /// Restores a single route from stored settings.
  Route? restoreRoute() => Control.get<RouteStore>()?.routing.restore(this);

  /// Restores a route and its sub-routes from stored settings and navigates to them.
  Future<dynamic> restoreNavigation(
          [List<dynamic> subRoutes = const []]) async =>
      Control.get<RouteStore>()
          ?.routing
          .restoreRouteNavigation(this, navigator, subRoutes);
}
