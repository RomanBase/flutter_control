import 'package:flutter_control/core.dart';

import 'spend_control.dart';

class SpendItemControl extends BaseControl with RouteControlProvider {
  final title = InputControl(regex: '.{3,}');
  final note = InputControl();
  final value = InputControl();
  final savings = InputControl();

  final sub = BoolControl();

  SpendItem get item => SpendItem(
        title: title.value,
        note: note.value,
        value: Parse.toDouble(value.value),
        possibleSavings: Parse.toDouble(value.value),
        subscription: sub.value,
      );

  SpendItem origin;

  @override
  void onInit(Map args) {
    super.onInit(args);

    origin = args.getArg<SpendItem>();

    if (origin != null) {
      title.value = origin.title;
      note.value = origin.note;
      value.value = origin.value.toString();
      savings.value = origin.value.toString();
      sub.value = origin.subscription;
    }

    title.done(_updateData).next(note).done(_updateData).next(value).done(_updateData).next(savings).done(_updateData);

    sub.subscribe((_) => _updateData());
  }

  void _updateData() {}

  void submit() {
    if (!title.validateChain()) {
      return;
    }

    if (origin == null) {
      Control.get<SpendControl>().addItem(item);
    } else {
      Control.get<SpendControl>().updateItem(origin, item);
    }

    close();
  }
}
