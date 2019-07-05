Flutter Control helps to separate Business Logic from UI and works based on BLoC and Provider patterns, but with little twist.
Whole Logic is based in Controller or Model classes and Widgets are notified about changes via Streams.

---

**Example**

Controller handles all Business Logic. Simply adds and removes items from List and recalculates item done count.
[StringControl] and [ListControl] wraps [Stream] and notifies [FieldBuilder] about changes.
```dart
class TodoController extends BaseController {
  final doneCount = StringControl();
  final items = ListControl<TodoItemModel>();
  final input = InputController(regex: '.{3,}');

  TodoController() {
    items.subscribe((list) => _recalculateCount());
    input.done(addInputItem);
  }

  void addInputItem() {
    if (!input.validate()) {
      input.setError('invalid value');
      return;
    }

    items.add(TodoItemModel(this, input.value));

    input.setText(null);
  }

  void removeItem(TodoItemModel item) => items.remove(item);

  void _recalculateCount() => doneCount.setValue("${items.where((item) => item.done.isTrue).length}/${items.length}");

  @override
  void dispose() {
    super.dispose();

    items.clear(disposeItems: true);
    items.dispose();
  }
}
```

Model holds state of one item in list and notifies parent controller about changes.
```dart
class TodoItemModel implements Disposable {
  final done = BoolControl();
  final String title;

  TodoItemModel(TodoController parent, this.title) {
    done.subscribe((value) => parent._recalculateCount());
  }

  @override
  void dispose() {
    done.dispose();
  }
}
```

Control and App initialization. TodoController is initialized and stored in global [ControlFactory].
```dart
class MainApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseApp(
      title: 'Flutter Control',
      theme: ThemeData(),
      entries: {
        'todo': TodoController(),
      },
      root: (context) => TodoPage(),
    );
  }
}
```

List and Item builders.
State management is handled by Controller and separate Widgets are build via [FieldBuilder].
Controller is automatically provided by [ControlFactory].
Controller can be provided manually or multiple controllers can be set to work with [ControlWidget].
```dart
class TodoPage extends SingleControlWidget<TodoController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TODO List'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: FieldBuilder<String>(
                controller: controller.doneCount,
                builder: (BuildContext context, String value) {
                  return Text(value);
                },
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListBuilder<TodoItemModel>(
              controller: controller.items,
              builder: (context, items) {
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FieldBuilder<bool>(
                      key: ObjectKey(item),
                      controller: item.done,
                      builder: (context, isDone) {
                        return FlatButton(
                          onPressed: item.done.toggle,
                          child: Row(
                            children: <Widget>[
                              Checkbox(
                                value: isDone,
                                onChanged: (checked) => item.done.setValue(checked),
                              ),
                              Text(
                                item.title,
                                style: isDone ? theme.textTheme.body1.copyWith(decoration: TextDecoration.lineThrough) : theme.textTheme.body1,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Container(
            color: theme.primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: InputField(
                controller: controller.input,
                textInputAction: TextInputAction.next,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

---

**Control Classes**

- [BaseApp] Wraps MaterialApp and initializes Control and Factory. It's just shortcut to start with Flutter Control.
- [AppControl] Is [InheritedWidget] around whole App. Holds Factory and other important Controllers.
- [ControlFactory] Mainly initializes and stores Controllers, Models and other Logic classes. Also works as global Stream to provide communication and synchronization between separated parts of App.

- [ActionControl] Single or Broadcast Observable. Usable with [ControlBuilder] to dynamically build Widgets.
- [FieldControl] Stream wrapper to use with [FieldStreamBuilder] or [FieldBuilder] to dynamically build Widgets.

- [BaseController] Stores all Business Logic and initializes self during Widget construction. Have native access to Factory and Control.
- [StateController] Adds functionality to notify State of [ControlWidget].
- [RouteController] Mixin for [BaseController] to enable Control Route Navigator. ([ControlWidget] must implement [RouteControl])
- [BaseModel] Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.  

- [ControlWidget] Base Widget to work with Controllers. Have native access to Factory and Control. 
- [BaseControlWidget] Widget with no init Controllers, but still have access to Factory etc. so Controllers can be get from there.
- [SingleControlWidget] Widget with just one generic Controller.
- [RouteControl] Mixin for [ControlWidget] to enable Control Route Navigation. ([BaseController] must implement [RouteController])
- [TickerControl] Mixin for [ControlWidget] to provide TickerProvider for AnimationControllers.