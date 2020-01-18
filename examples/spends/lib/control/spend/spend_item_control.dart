import 'package:flutter_control/core.dart';
import 'package:spends/control/spend/spend_group_control.dart';
import 'package:spends/entity/spend_item.dart';

import 'spend_control.dart';
import 'spend_item_model.dart';

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

  SpendControl get spendControl => Control.get<SpendControl>();
  SpendGroupControl groupControl;
  SpendItemModel model;

  bool get editMode => model != null;

  bool get inGroup => groupControl != null;

  @override
  void onInit(Map args) {
    super.onInit(args);

    model = args.getArg<SpendItemModel>();
    groupControl = args.getArg<SpendGroupControl>();

    if (model != null) {
      title.value = model.item.title;
      note.value = model.item.note;
      value.value = model.item.value.toString();
      type.value = model.item.type;
    }

    if (groupControl != null) {
      group.value = groupControl.group.item.id;
    }

    title.done(_updateData).next(note).done(_updateData).next(value).done(_updateData).done(_updateData);
  }

  void _updateData() {}

  void submit() {
    if (!title.validateChain()) {
      return;
    }

    if (inGroup) {
      if (editMode) {
        if (groupControl.group.item.id != group.value) {
          groupControl.removeItem(model);
          spendControl.addItem(item);
        } else {
          groupControl.updateItem(model, item);
        }
      } else {
        groupControl.addItem(item);
      }
    } else {
      if (editMode) {
        spendControl.updateItem(model, item);
      } else {
        spendControl.addItem(item);
      }
    }

    close();
  }
}
