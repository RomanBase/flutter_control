import 'package:flutter_control/core.dart';
import 'package:spends/entity/spend_item.dart';

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

  SpendItemModel model;

  bool get editMode => model != null;

  @override
  void onInit(Map args) {
    super.onInit(args);

    model = args.getArg<SpendItemModel>();

    if (model != null) {
      title.value = model.item.title;
      note.value = model.item.note;
      value.value = model.item.value.toString();
      savings.value = model.item.value.toString();
      sub.value = model.item.subscription;
    }

    title.done(_updateData).next(note).done(_updateData).next(value).done(_updateData).next(savings).done(_updateData);

    sub.subscribe((_) => _updateData());
  }

  void _updateData() {}

  void submit() {
    if (!title.validateChain()) {
      return;
    }

    if (editMode) {
      Control.get<SpendControl>().updateItem(model, item);
    } else {
      Control.get<SpendControl>().addItem(item);
    }

    close();
  }
}
