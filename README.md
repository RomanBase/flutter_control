**Alpha version of Flutter Control**

Stable but needs more testing and little care..

---

Flutter Control helps to separate Business Logic from UI and works based on BLoC and Provider patterns, but with little twist.
Whole Logic is based in Controller or Model classes and Widgets are notified about changes via Streams.

![Structure](/docs/structure_simple.png)

---

**Base classes**

- [BaseApp] Wraps MaterialApp and initializes Control and Factory. It's just shortcut to start with Flutter Control.
- [AppControl] Is [InheritedWidget] around whole App.
- [ControlFactory] Mainly initializes and stores Controllers, Models and other Logic classes. Also works as global Stream to provide easy communication and synchronization between separated parts of App.
- [BaseLocalization] Json based localization, that supports simple strings, plurals and dynamic structures.
- [RouteHandler] Initializes Widget and handles Navigation.

---

**Streams**

- [ActionControl] Single or Broadcast Observable. Usable with [ControlBuilder] to dynamically build Widgets.
- [FieldControl] Stream wrapper to use with [FieldStreamBuilder] or [FieldBuilder] to dynamically build Widgets.
- [ListControl] Extended FieldControl to work with [Iterable]. And with [ListBuilder] to dynamically build list of Widgets.
- [LoadingControl], [StringControl], [BoolControl], etc. with builders..

---

**Controllers**

- [BaseControlModel] Stores all Business Logic and initializes self during Widget construction.
- [BaseController] Extended version of [BaseControlModel] with more functionality.
- [BaseModel] Extended but lightweight version of [BaseControlModel]. Mainly used for Items in dynamic List or to separate/reuse Logic.
- [InputController] Controller for [InputField] to control text, changes, validity, focus, etc. Controllers can be chained via 'next' and 'done' events.
- [NavigatorController] Controller for [NavigatorStack.single] to control navigation inside Widget.
- [NavigatorStackController] Controller for [NavigatorStack.pages] or [NavigatorStack.menu] to control navigation between Widgets.

---

**Widgets**

- [ControlWidget] Base Widget to work with ControlModel. 
- [BaseControlWidget] Widget with no init ControlModel, but still have access to Factory etc. so Controllers can be get from there.
- [SingleControlWidget] Widget with just one ControlModel.

- [InputField] Wrapper of [TextField] to provide more functionality and control via [InputController].
- [FieldBuilder] Dynamic Widget builder controlled by [FieldControl].
- [FieldBuilderGroup] Dynamic Widget builder controlled by multiple [FieldControl]s. 
- [ListBuilder] Wrapper of [FieldBuilder] to easily work with Lists.
- [ControlBuilder] Dynamic Widget builder controlled by [ActionControl].
- [StableWidget] Widget that is build just once.

- [NavigatorStack.single] Enables navigation inside Widget.
- [NavigatorStack.pages] Enables navigation between Widgets. Usable for menus, tabs, etc.
- [NavigatorStack.menu] Same as 'pages', but Widgets are generated from [MenuItem] data.

---

**Providers**

- [ControlProvider] Provides and initializes objects from [ControlFactory].
- [BroadcastProvider] Globally broadcast events and data.
- [PageRouteProvider] Specifies Route and WidgetBuilder settings for [RouteHandler].

---

**Mixins**

- [LocalizationProvider] - mixin for any class, enables [BaseLocalization] for given object.
- [StateController] - mixin for [BaseControlModel] to notify State of Widget.
- [RouteControl] - mixin for [ControlWidget], enables route navigation.
- [RouteController] - mixin for [BaseControlModel], enables route navigation bridge to [ControlWidget] with [RouteControl]. 
- [TickerControl] - mixin for [ControlWidget], enables Ticker for given Widget.

- [DisposeHandler] - mixin for any class, helps with object disposing.
- [PrefsProvider] - mixin for any class, helps to store user preferences.

---

**Helpers**

- [FutureBlock] Retriggerable delay.
- [DelayBlock] Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.
- [Parse] Helps to parse json primitives and Iterables. Provides default values if parsing fails.
- [Device] Wrapper over [MediaQuery].
- [WidgetInitializer] Helps to initialize Widgets with init data.
- [BaseTheme] Some basic values to work with during Widget composition.

- and more..

---

**Example**

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
class TodoItemModel extends BaseModel {
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