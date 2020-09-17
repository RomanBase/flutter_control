import 'package:flutter_control/core.dart';
import 'package:spends/control/earnings/earnings_control.dart';
import 'package:spends/control/earnings/earnings_item_model.dart';
import 'package:spends/entity/earnings_item.dart';

class EarningsItemControl extends BaseControl with RouteControlProvider {
  final title = InputControl(regex: '.{3,}');

  var note = InputControl();

  var value = InputControl();

  final type = ActionControl.broadcast<EarningsType>(EarningsType.normal);

  EarningsControl get earningsControl => Control.get<EarningsControl>();

  EarningsItemModel model;

  bool get editMode => model != null;

  EarningsItem get item => EarningsItem(
        title: title.text,
        note: note.text,
        value: Parse.toDouble(value.value),
        type: type.value,
      );

  @override
  void onInit(Map args) {
    super.onInit(args);

    model = args.getArg<EarningsItemModel>();

    if (model != null) {
      title.text = model.item.title;
      value.text = model.item.value.toInt().toString();
      note.text = model.item.note;
      type.value = model.item.type;
    }
  }

  void submit() {
    if (editMode) {
      earningsControl.updateItem(model, item);
    } else {
      earningsControl.addItem(item);
    }

    close();
  }
}
