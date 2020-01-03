import 'package:flutter/cupertino.dart';
import 'package:flutter_control/core.dart';

/// Abstract implementation of simple widget initializer and holder.
abstract class WidgetInitializer {
  /// Current Widget.
  Widget _widget;

  /// Init data.
  /// Send to Widget via [_args] with [ControlKey.initData] key.
  Object data;

  bool get isInitialized => _widget != null;

  WidgetInitializer();

  factory WidgetInitializer.of(WidgetBuilder builder) => _WidgetInitBuilder(builder);

  static WidgetInitializer control<T>(ControlWidgetBuilder<T> builder) => _WidgetInitControlBuilder(builder);

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

    return _widget;
  }

  bool isValid() {
    if (_widget is ControlWidget) {
      return (_widget as ControlWidget).isValid;
    }

    return true;
  }

  Map _buildArgs(dynamic args) {
    final buildArgs = ControlArgs(args);

    buildArgs.set(data);

    return buildArgs.args;
  }

  /// Wraps initializer into [WidgetBuilder].
  WidgetBuilder wrap({dynamic args}) => (context) => getWidget(context, args: args);
}

/// Simple [WidgetBuilder] and holder.
class _WidgetInitBuilder extends WidgetInitializer {
  /// Current builder.
  final WidgetBuilder builder;

  /// Default constructor
  _WidgetInitBuilder(this.builder) {
    assert(builder != null);
  }

  @override
  Widget initWidget(BuildContext context, {dynamic args}) {
    final widget = builder(context);

    if (widget is Initializable) {
      (widget as Initializable).init(_buildArgs(args));
    }

    return widget;
  }
}

class _WidgetInitControlBuilder<T> extends WidgetInitializer {
  final ControlWidgetBuilder<T> builder;

  _WidgetInitControlBuilder(this.builder);

  @override
  Widget initWidget(BuildContext context, {args}) {
    final initArgs = _buildArgs(args);

    final widget = builder(context, Parse.getArg<T>(initArgs));

    if (widget is Initializable) {
      (widget as Initializable).init(initArgs);
    }

    return widget;
  }
}

class WidgetInit extends StatefulWidget {
  final Widget child;
  final Map args;

  const WidgetInit({Key key, this.child, this.args}) : super(key: key);

  @override
  _WidgetInitState createState() => _WidgetInitState();
}

class _WidgetInitState extends State<WidgetInit> {
  @override
  void initState() {
    super.initState();

    if (widget.child is Initializable) {
      (widget.child as Initializable).init(widget.args);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
