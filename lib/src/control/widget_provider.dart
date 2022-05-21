part of flutter_control;

class InitBuilderArgs extends ControlArgs {
  final BuildContext context;

  InitBuilderArgs(this.context, [dynamic args]) : super(args);
}

/// Abstract implementation of simple widget initializer and holder.
abstract class WidgetInitializer implements Disposable {
  /// Current Widget.
  Widget? _widget;

  Widget? get value => _widget;

  /// Init data.
  /// Send to Widget via [_args] with [ControlKey.initData] key.
  Object? data;

  Key? key;

  bool get isInitialized => _widget != null;

  WidgetInitializer();

  factory WidgetInitializer.of(WidgetBuilder builder, [Object? data]) =>
      _WidgetWrapBuilder(builder)..data = data;

  factory WidgetInitializer.initOf(InitWidgetBuilder builder, [Object? data]) =>
      _WidgetInitBuilder(builder)..data = data;

  /// Widget initialization - typically called just once.
  /// Or when new initialization is forced.
  @protected
  Widget initWidget(BuildContext context, {dynamic args});

  /// Returns current Widget or tries to initialize new one.
  /// [forceInit] to re-init widget.
  Widget getWidget(BuildContext context, {forceInit: false, dynamic args}) {
    if (forceInit || _widget == null || !isValid()) {
      _widget = initWidget(context, args: args);
    }

    return _widget!;
  }

  bool isValid() {
    if (_widget is ControlWidget) {
      return (_widget as ControlWidget).isValid;
    }

    return true;
  }

  Map _buildArgs(dynamic args) => Parse.toArgs(args, data: data);

  /// Wraps initializer into [WidgetBuilder].
  WidgetBuilder wrap({dynamic args}) =>
      (context) => getWidget(context, args: args);

  void clear() {
    _widget = null;
  }

  @override
  void dispose() {
    _widget = null;
    data = null;
    key = null;
  }
}

/// Simple [WidgetBuilder].
class _WidgetWrapBuilder extends WidgetInitializer {
  /// Current builder.
  final WidgetBuilder builder;

  /// Default constructor
  _WidgetWrapBuilder(this.builder);

  @override
  Widget initWidget(BuildContext context, {dynamic args}) {
    final widget = builder(context);

    if (widget is Initializable) {
      (widget as Initializable).init(_buildArgs(args));
    }

    return widget;
  }
}

/// Simple [WidgetBuilder].
class _WidgetInitBuilder extends WidgetInitializer {
  /// Current builder.
  final InitWidgetBuilder builder;

  /// Default constructor
  _WidgetInitBuilder(this.builder);

  @override
  Widget initWidget(BuildContext context, {dynamic args}) {
    args = _buildArgs(args);
    final widget = builder(InitBuilderArgs(context, args));

    if (widget is Initializable) {
      (widget as Initializable).init(args);
    }

    return widget;
  }
}
