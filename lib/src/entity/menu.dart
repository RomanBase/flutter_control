import 'package:flutter_control/core.dart';

typedef MenuCallback<T> = T Function(bool selected);

class MenuItem {
  final Object key;
  final MenuCallback<dynamic> iconBuilder;
  final MenuCallback<String> titleBuilder;
  final Object data;
  final bool selected;
  final ValueGetter<bool> onSelected;

  dynamic get icon => iconBuilder != null ? iconBuilder(selected) : null;

  String get title => titleBuilder != null ? titleBuilder(selected) : null;

  const MenuItem({
    this.key,
    this.iconBuilder,
    this.titleBuilder,
    this.data,
    this.selected: false,
    this.onSelected,
  });

  MenuItem copyWith({
    Object key,
    Object data,
    bool selected,
  }) =>
      MenuItem(
        key: key ?? this.key,
        iconBuilder: iconBuilder ?? this.iconBuilder,
        titleBuilder: titleBuilder ?? this.titleBuilder,
        data: data ?? this.data,
        selected: selected ?? this.selected,
      );
}
