import 'package:flutter/foundation.dart';
import 'package:flutter_control/core.dart';

class BaseNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  @override
  T get value => _value;

  set value(T newValue) {
    _value = newValue;
    notifyListeners();
  }

  BaseNotifier([T value]) {
    _value = value;
  }

  void notify() => notifyListeners();
}

class NotifierBuilder<T> extends StatefulWidget {
  final Listenable control;
  final ControlWidgetBuilder<T> builder;

  const NotifierBuilder({
    Key key,
    @required this.control,
    @required this.builder,
  }) : super(key: key);

  factory NotifierBuilder.of({
    Key key,
    @required StateControl control,
    @required ControlWidgetBuilder<T> builder,
  }) =>
      NotifierBuilder(key: key, control: control.state, builder: builder);

  @override
  State<StatefulWidget> createState() => _NotifierBuilderState();

  Widget build(BuildContext context) {
    if (control is ValueNotifier) {
      final value = (control as ValueListenable).value;

      if (value is T) {
        return builder(context, value);
      }
    }

    if (control is T) {
      return builder(context, control as T);
    } else {
      return builder(context, null);
    }
  }
}

class _NotifierBuilderState extends State<NotifierBuilder> {
  @override
  void initState() {
    super.initState();

    widget.control.addListener(_updateState);
  }

  void _updateState() => setState(() {});

  @override
  void didUpdateWidget(NotifierBuilder oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.control != widget.control) {
      oldWidget.control.removeListener(_updateState);
      widget.control.addListener(_updateState);
    }
  }

  @override
  Widget build(BuildContext context) => widget.build(context);

  @override
  void dispose() {
    super.dispose();

    widget.control.removeListener(_updateState);
  }
}
