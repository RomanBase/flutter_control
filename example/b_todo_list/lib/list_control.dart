import 'package:flutter_control/core.dart';

class TodoItemModel extends BaseModel with ObservableComponent {
  final String title;

  bool _isDone;

  bool get isDone => _isDone;

  set isDone(value) {
    _isDone = value;
    notify();
  }

  TodoItemModel(this.title, [this._isDone = false]);

  void toggle() => isDone = !isDone;
}

class TodoListControl extends BaseControl {
  final list = ListControl<TodoItemModel>();

  void addItem(String title) => list.add(TodoItemModel(title));

  bool updateItem(TodoItemModel model, String title) =>
      list.replace(TodoItemModel(title, model.isDone), (item) => item == model);

  bool removeItem(TodoItemModel model) => list.remove(model);

  void clear() async {
    while (list.length > 0) {
      list.removeAt(0);

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  void fillTestData() async {
    int index = 0;
    while (index < 50) {
      addItem(UnitId.charId(index++));

      await Future.delayed(const Duration(milliseconds: 10));
    }
  }

  @override
  void dispose() {
    super.dispose();

    list.clear(disposeItems: true);
    list.dispose();
  }
}

class ItemDialogControl extends BaseControl {
  final title = InputControl(regex: '.{1,}');

  TodoItemModel model;

  bool get editMode => model != null;

  TodoListControl get control => Control.get<TodoListControl>();

  @override
  void onInit(Map args) {
    super.onInit(args);

    model = args.getArg<TodoItemModel>();

    if (model != null) {
      title.text = model.title;
    }
  }

  bool submit() {
    if (!title.validate()) {
      title.error = 'invalid title length';
      return false;
    }

    if (editMode) {
      control.updateItem(model, title.text);
    } else {
      control.addItem(title.text);
    }

    return true;
  }

  bool remove() => control.removeItem(model);

  @override
  void dispose() {
    super.dispose();
    title.dispose();
  }
}
