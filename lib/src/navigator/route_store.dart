part of flutter_control;

abstract class RoutingStoreProvider {
  List<ControlRoute> get routes;

  RoutingStoreProvider();

  factory RoutingStoreProvider.of({List<ControlRoute> routes = const [], List<RoutingStoreProvider> providers = const []}) => _RoutingStoreProvider(
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

class RoutingModule extends ControlModule<RouteStore> {
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

class RouteArgs extends ControlArgs {
  ControlRoute get route => get<ControlRoute>()!;

  RouteMask get mask => get<RouteMask>()!;

  RouteArgs._(ControlRoute route, RouteMask mask, [dynamic args]) : super(ControlArgs.of(args).data) {
    add(value: route);
    add(value: mask);
  }

  String format(dynamic args, [ParamDecoratorFormat? decorator]) => mask.format(args, decorator);
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
        printDebug('Storage already contains key: $identifier. Route of this key will be override.');
      }
      return true;
    }());

    _routes[identifier] = route;
    _masks.add(RouteMask.of(route._mask ?? identifier, identifier));

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
    final mask = _masks.firstWhere((element) => element.match(identifier), orElse: () => RouteMask.empty);

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
  static String routePathIdentifier<T>({dynamic identifier, dynamic path, dynamic args}) {
    if (path == null) {
      path = routeIdentifier(identifier);
    } else if (path is String) {
      if (!path.startsWith('/')) {
        path = '/$path';
      }
    } else if (path is List) {
      path = '/' + path.join('/');
    } else if (path is Map) {
      path = '/' + Parse.toList(args, entryConverter: (key, value) => '$key/$value').join('/');
    }

    if (args == null || (args is String && args.isEmpty)) {
      return path;
    }

    if (args is Map) {
      return '$path?' + Parse.toList(args, entryConverter: (key, value) => '$key=$value').join('&');
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

  List<String> get args => _segments.where((e) => e.mask).map((e) => e.name).toList();

  bool get isEmpty => _segments.isEmpty;

  bool get isNotEmpty => _segments.isNotEmpty;

  int get segmentCount => _segments.length;

  static RouteMask get root => RouteMask._([_PathSegment('', false, null)], '/');

  static RouteMask get empty => RouteMask._([], '/');

  const RouteMask._(this._segments, this.identifier);

  factory RouteMask.of(String? path, [String? identifier]) => path == null ? empty : (path == '/' ? root : RouteMask._(_PathSegment.chain(Uri.parse(path, 0, path.endsWith('/') ? path.length - 1 : path.length).pathSegments), identifier ?? path));

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
      return Parse.format(path, Parse.toKeyMap(args, (key, value) => '$key', converter: (value) => '$value'), decorator);
    }

    return Parse.format(path, {this.args.first: '$args'}, ParamDecorator.none);
  }

  Map<String, dynamic> params(RouteMask other, [int decoratorStartOffset = 1, int decoratorEndOffset = 1]) {
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
        map[mask._segments[i].substringName(decoratorStartOffset, decoratorEndOffset)] = route._segments[i].name;
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

  String substringName(int startOffset, int endOffset) => name.substring(startOffset, name.length - endOffset);

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

  RouteFactory? onGenerate;

  RoutingProvider._(this.parent);

  RouteSettings? popSettings(BuildContext context) => (context is RootContext ? context : context.root).args.pop<RouteSettings>();

  Route? generate(BuildContext context, RouteSettings settings, {bool? active, RouteFactory? onGenerate}) {
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

  Route? restore(BuildContext context) {
    final settings = popSettings(context);

    if (settings != null) {
      return generate(context, settings);
    }

    return null;
  }

  Future restoreRouteNavigation(BuildContext context, RouteNavigator navigator) async {
    final route = restore(context);

    if (route != null) {
      return navigator.openRoute(route);
    }

    return null;
  }
}
