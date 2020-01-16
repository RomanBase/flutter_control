import 'package:flutter_control/core.dart';
import 'package:spends/entity/spend_item.dart';

import 'spend_control.dart';

class SpendItemControl extends BaseControl with RouteControlProvider {
  final title = InputControl(regex: '.{3,}');
  final note = InputControl();
  final value = InputControl();

  final type = ActionControl.broadcast<SpendType>(SpendType.normal);
  final group = ActionControl.broadcast<String>('none');

  List<SpendItem> get groups => Control.get<SpendControl>().groups;

  SpendItem get item => SpendItem(
        title: title.value,
        note: note.value,
        value: Parse.toDouble(value.value),
        type: type.value,
        groupId: group.value != 'none' ? group.value : null,
        items: type.value == SpendType.group ? [] : null,
      );

  SpendItemModel model;

  bool get editMode => model != null;

  @override
  void onInit(Map args) {
    super.onInit(args);

    model = args.getArg<SpendItemModel>();
    group.value = args.getArg<String>(defaultValue: 'none');

    if (model != null) {
      title.value = model.item.title;
      note.value = model.item.note;
      value.value = model.item.value.toString();
      type.value = model.item.type;
    }

    title.done(_updateData).next(note).done(_updateData).next(value).done(_updateData).done(_updateData);
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
