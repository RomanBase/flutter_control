part of flutter_control;

typedef RouteWidgetBuilder = Route Function(
    WidgetBuilder builder, RouteSettings settings);

typedef RouteGenerateBuilder = Route? Function(RouteSettings settings);

typedef RouteArgInitializer = dynamic Function(RouteArgs args);

class RouteArgs extends ControlArgs {
  ControlRoute get route => get<ControlRoute>()!;

  RouteMask get mask => get<RouteMask>()!;

  RouteArgs._(ControlRoute route, RouteMask mask, [dynamic args])
      : super(args) {
    add(value: route);
    add(value: mask);
  }
}

class RoutingModule extends ControlModule<RouteStore> {
  final List<ControlRoute> routes;

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
  Future? init() => null;
}

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
  void backToRoot({Route? open});

  /// {@template route-back-to}
  /// Goes back in navigation stack until [Route] found.
  /// {@endtemplate}
  void backTo<T>({
    Route? route,
    String? identifier,
    bool Function(Route<dynamic>)? predicate,
    Route? open,
  });

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
  final RouteNavigator navigator;

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
  RouteHandler(this.navigator, this.routeProvider);

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
  RouteHandler path(
          {Initializer<dynamic>? name, Initializer<dynamic>? query}) =>
      RouteHandler(navigator, routeProvider.path(name: name, query: query));

  /// Creates copy of [RouteHandler] with given identifier.
  ///
  /// @{macro route-named}
  RouteHandler named(String identifier) =>
      RouteHandler(navigator, routeProvider.named(identifier));

  /// @{macro route-open}
  Future<dynamic>? openRoute(
      {bool root: false, bool replacement: false, dynamic args}) {
    printDebug("open route: ${routeProvider.identifier} from $navigator");

    _result = navigator.openRoute(
      _route = routeProvider.init(args: args),
      root: root,
      replacement: replacement,
    );

    return _result;
  }

  /// {@macro route-root}
  Future<dynamic>? openRoot({dynamic args}) {
    printDebug("open root: ${routeProvider.identifier} from $navigator");

    _result = navigator.openRoot(_route = routeProvider.init(args: args));

    return _result;
  }

  /// @{macro route-dialog}
  Future<dynamic> openDialog({bool root: true, dynamic type, dynamic args}) {
    printDebug("open dialog: ${routeProvider.identifier} from $navigator");

    _route = null;
    return _result = navigator.openDialog(
      routeProvider.buildInitializer().wrap(args: args),
      root: root,
      type: type,
    );
  }
}

/// [Route] builder with given settings.
/// Using [Type] as route identifier is recommended.
class ControlRoute {
  static get _store => Control.get<RouteStore>()!;

  static RoutingProvider get provider => _store.provider;

  /// Builds [Route] via [builder] with given [identifier] and [settings].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  /// [mask] - specific url mask, that can be used for dynamic routing - check [RouteStore.routePathMask] for more info. E.g. /project/{pid}/user{uid}
  /// [settings] - Additional [Route] settings.
  ///
  /// Typically used within [Control.initControl] or [ControlRoot].
  /// ```
  ///   routes: [
  ///     ControlRoute.build<SettingsPage>(builder: (_) => SettingsPage()),
  ///     ControlRoute.build(identifier: 'settings', builder: (_) => SettingsPage()),
  ///   ]
  /// ```
  /// Using [Type] as route identifier is recommended.
  static ControlRoute build<T>({
    dynamic identifier,
    String? mask,
    Object? arguments,
    required InitWidgetBuilder builder,
  }) {
    assert(T != dynamic || identifier != null);

    return ControlRoute._()
      ..identifier = RouteStore.routeIdentifier<T>(identifier)
      ..mask = mask
      ..arguments = arguments
      .._builder = builder;
  }

  /// Holds [Route] with given [identifier].
  /// Useful for specific or generated Routes.
  ///
  /// Check [RouteControl.build] for classic [WidgetBuilder] version.
  static ControlRoute route<T>({
    dynamic identifier,
    String? mask,
    required Route route,
  }) =>
      ControlRoute._()
        ..identifier = RouteStore.routeIdentifier<T>(identifier)
        ..mask = mask
        .._routeBuilder = (_, __) => route;

  /// @{template route-store-get}
  /// Returns [ControlRoute] from [RouteStore] by given [Type] or [identifier].
  /// [Type] or [identifier] is required - check [RouteStore.routeIdentifier] for more info about Store keys.
  ///
  /// [RouteStore] is typically filled during [Control.initControl] or via [ControlRoot].
  /// [RouteStore] is also stored in [Control] -> [Control.get<RouteStore>()] and can be updated anytime,
  ///
  /// Using [Type] as route identifier is recommended.
  /// @{endtemplate}
  static ControlRoute? of<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier);
  }

  /// Returns identifier of Route stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  static String? identifierOf<T>([dynamic identifier]) {
    assert(T != dynamic || identifier != null);

    return _store.getRoute<T>(identifier)?.identifier;
  }

  /// Route name. This identifier is typically stored in [RouteStore].
  /// Check [RouteStore.routeIdentifier] for more info about Store keys.
  late String identifier;

  String? mask;

  /// Additional route settings.
  Object? arguments;

  /// Required Widget builder.
  InitWidgetBuilder? _builder;

  /// Custom Route builder.
  RouteWidgetBuilder? _routeBuilder;

  RouteArgInitializer? _pathBuilder;

  RouteArgInitializer? _queryBuilder;

  /// Default private constructor.
  /// Use static constructors - [ControlRoute.build], [ControlRoute.route] or [ControlRoute.of].
  ControlRoute._();

  WidgetInitializer buildInitializer() {
    assert(_builder != null);

    return WidgetInitializer.initOf(_builder!);
  }

  String _buildPath(RouteArgs args) => RouteStore.routePathIdentifier(
        identifier: identifier,
        path: _pathBuilder?.call(args),
        args: _queryBuilder?.call(args),
      );

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  Route _buildRoute(WidgetBuilder builder, String? path) {
    final routeSettings =
        RouteSettings(name: path ?? identifier, arguments: arguments);

    if (_routeBuilder != null) {
      return _routeBuilder!(builder, routeSettings);
    }

    if (kIsWeb) {
      return MaterialPageRoute(builder: builder, settings: routeSettings);
    }

    if (Platform.isIOS) {
      return CupertinoPageRoute(builder: builder, settings: routeSettings);
    }

    return MaterialPageRoute(builder: builder, settings: routeSettings);
  }

  /// Builds [Route] with specified [RouteWidgetBuilder] or with default [MaterialPageRoute]/[CupertinoPageRoute].
  /// Also [identifier] and [settings] are passed to Route as [RouteSettings].
  /// Given [args] are passed to Widget.
  Route init({dynamic args}) {
    assert(_builder != null);

    final initializer = buildInitializer();

    final route = _buildRoute(
      initializer.wrap(args: args),
      _buildPath(RouteArgs._(this, RouteMask.of(mask ?? identifier), args)),
    );

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
  /// Alters current [identifier] with given [name] and [query] args and returns copy of [ControlRoute] with new settings.
  /// ```
  /// ControlRoute.of<DetailPage>(identifier: 'detail').path(path: (_) => 'node', query: (args) => {'id': args['id']});
  /// refers to: /detail/node?id=1
  /// ```
  /// {@endtemplate}
  ControlRoute path(
          {RouteArgInitializer? name,
          RouteArgInitializer? query,
          String? mask}) =>
      _copyWith(
        path: name,
        query: query,
        mask: mask,
      );

  /// {@template route-name}
  /// Changes current [identifier] and returns copy of [ControlRoute] with new settings..
  /// {@endtemplate}
  ControlRoute named(String identifier) => _copyWith(
        identifier: identifier,
      );

  /// Creates copy of [RouteControl] with given settings.
  ControlRoute _copyWith({
    dynamic identifier,
    String? mask,
    Object? arguments,
    RouteWidgetBuilder? routeBuilder,
    RouteArgInitializer? path,
    RouteArgInitializer? query,
  }) =>
      ControlRoute._()
        ..identifier = identifier ?? this.identifier
        ..mask = mask ?? this.mask
        ..arguments = arguments ?? this.arguments
        .._builder = _builder
        .._routeBuilder = routeBuilder ?? this._routeBuilder
        .._pathBuilder = path
        .._queryBuilder = query;

  /// Initializes [RouteHandler] with given [navigator] and this Route provider.
  RouteHandler navigator(RouteNavigator navigator) =>
      RouteHandler(navigator, this);

  /// Registers this Route to global [RouteStore].
  void register<T>() => _store.addRoute<T>(this);
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
  late RoutingProvider routing = RoutingProvider._(this);

  /// Map based Route Store.
  /// Key: [RouteStore.routeIdentifier].
  /// Value: [RouteControl].
  final _routes = Map<String, ControlRoute>();

  final _masks = <RouteMask>[];

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

  /// Adds given [route] to [RouteStore].
  /// Returns store key.
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
    _masks.add(RouteMask.of(route.mask ?? identifier, identifier));

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

    identifier = RouteMask.of(identifier);
    final mask = _masks.firstWhere((element) => element.match(identifier),
        orElse: () => RouteMask.empty);

    if (mask.isNotEmpty && _routes.containsKey(mask.identifier)) {
      return _routes[mask.identifier];
    }

    return null;
  }

  /// Resolves identifier for given route [Type] and [name].
  /// Similar to [ControlFactory.keyOf], but also accepts [String] as valid [value] key.
  /// This method is mainly used by framework to determine identifier of [ControlRoute] stored in [RouteStore].
  ///
  /// Returned identifier is formatted as path -> '/name'.
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

  /// Alters given [identifier] with [path].
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

  String format(dynamic args, [ParamDecoratorFormat? decorator]) {
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

      return Parse.format(path, map, ParamDecorator.none);
    }

    if (args is Map) {
      return Parse.format(
          path,
          Parse.toKeyMap(args, (key, value) => '$key',
              converter: (value) => '$value'),
          decorator);
    }

    return Parse.format(path, {this.args.first: '$args'}, ParamDecorator.none);
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

class RoutingProvider {
  final RouteStore parent;

  RouteGenerateBuilder? onGenerate;

  ControlRootSetup? get setup => ControlScope.root.setup;

  RouteSettings? get settings => setup?.args.get<RouteSettings>();

  RoutingProvider._(this.parent);

  RouteSettings? popSettings() => setup?.args.pop<RouteSettings>();

  Route? generate(RouteSettings settings,
      {bool? active, RouteGenerateBuilder? onGenerate}) {
    if (onGenerate != null) {
      this.onGenerate = onGenerate;
    }

    String? path = settings.name;

    if (path == null) {
      return null;
    }

    active ??= Control.isInitialized;

    if (!active) {
      ControlScope.root.setup?.args.set(settings);
      return null;
    }

    final args = ControlArgs(settings.arguments);

    final controlRoute = parent.getRoute(path);

    if (controlRoute != null) {
      final mask = RouteMask.of(controlRoute.mask ?? controlRoute.identifier);
      final params = mask.params(RouteMask.of(path));

      args.add(value: controlRoute);
      args.add(value: mask);
      params.forEach((key, value) => args.add(key: key, value: value));
    }

    if (this.onGenerate == null) {
      return controlRoute
          ?._copyWith(
            identifier: path,
            arguments: args.data,
          )
          .init(args: args.data);
    }

    return this.onGenerate?.call(RouteSettings(
          name: path,
          arguments: args.data,
        ));
  }

  Route? restore() {
    final settings = popSettings();

    if (settings != null) {
      return generate(settings);
    }

    return null;
  }

  Future restoreRouteNavigation(RouteNavigator navigator) async {
    final route = restore();

    if (route != null) {
      return navigator.openRoute(route);
    }

    return null;
  }
}
