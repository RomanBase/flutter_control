**Beta version of Flutter Control**

Stable, but needs more tests and little care..

[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://api.cirrus-ci.com/github/RomanBase/flutter_control)

---

Flutter Control is complex library to maintain App and State management.
And helps to separate Business Logic from UI and helps with Communication, Localization and Routing.

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure_simple.png)

---

**Base classes**

- [ControlApp] Wraps App and initializes Control with Global State, Factory and Localization. It's just shortcut to start with Flutter Control.
- [AppControl] Is [InheritedWidget] around whole App.
- [ControlFactory] Mainly initializes and stores Controllers, Models and other Logic classes. Also works as global Stream to provide easy communication and synchronization between separated parts of App.
- [BaseLocalization] Json based localization, that supports simple strings, plurals and dynamic structures.

---

**Streams and Observables**

- [ActionControl] Single or Broadcast Observable. Usable with [ControlBuilder] to dynamically build Widgets. Also to provide change events for other Controllers and Logic parts.
- [FieldControl] Stream wrapper to use with [FieldStreamBuilder] or [FieldBuilder] to dynamically build Widgets. Also to provide change events for other Controllers and Logic parts.
- [ListControl] Extended FieldControl to work with [Iterable]. And with [ListBuilder] to dynamically build list of Widgets.
- [LoadingControl], [StringControl], [BoolControl], etc. with builders..

---

**Controllers**

- [BaseControlModel] Stores all Business Logic and initializes self during Widget construction.
- [BaseController] Extended version of [BaseControlModel] with more functionality. Mainly used for pages or complex Widgets.
- [BaseModel] Extended but lightweight version of [BaseControlModel]. Mainly used for Items in dynamic List or to separate/reuse Logic parts.
- [InputController] Controller for [InputField] to control text, changes, validity, focus, etc. Controllers can be chained via 'next' and 'done' events.
- [NavigatorController] Controller for [NavigatorStack.single] to control navigation inside Widget.
- [NavigatorStackController] Controller for [NavigatorStack.pages] or [NavigatorStack.menu] to control navigation between pages. Mainly used with bottom menu.

---

**Widgets**

- [ControlWidget] Base Widget to work with [BaseControlModel]. 
- [BaseControlWidget] Widget with no init [BaseControlModel], but still have access to Factory etc. so Controllers can be get from there.
- [SingleControlWidget] Widget with just one [BaseControlModel].

- [InputField] Wrapper of [TextField] to provide more functionality and control via [InputController].
- [FieldBuilder] Dynamic Widget builder controlled by [FieldControl].
- [FieldBuilderGroup] Dynamic Widget builder controlled by multiple [FieldControl]s. 
- [ListBuilder] Wrapper of [FieldBuilder] to easily work with Lists. All primitives have own builder - [DoubleBuilder], [BoolBuilder], etc. 
- [ControlBuilder] Dynamic Widget builder controlled by [ActionControl].
- [StableWidget] Widget that is build just once. No mather how many times is build called. Rebuild can be forced via parameters..

- [NavigatorStack.single] Enables navigation inside Widget.
- [NavigatorStack.pages] Enables navigation between Widgets. Usable for menus, tabs, etc.
- [NavigatorStack.menu] Same as 'pages', but Widgets are generated from [MenuItem] data.

---

**Providers with static functionality**

- [ControlProvider] Provides and initializes objects from [ControlFactory].
- [BroadcastProvider] Globally broadcasts events and data.
- [ThemeProvider] Initializes [ControlTheme] and caches current [ThemeData].

---

**Routing**

- [RouteHandler] Initializes Widget and handles Navigation.
- [PageRouteProvider] Specifies Route and WidgetBuilder settings for [RouteHandler]. With [WidgetInitializer] passing args to Widgets and Controllers during navigation.
- [RouteNavigator] Interface to work with Navigator and Routes.

---

**Mixins**

- [LocalizationProvider] - mixin for any class, enables [BaseLocalization] for given object.
- [StateController] - mixin for [BaseControlModel] to notify State of Widget from Model/Controller.
- [RouteControl] - mixin for [ControlWidget], enables default route navigation.
- [RouteController] - mixin for [BaseControlModel], enables route navigation via [RouteHandler] bridge to [ControlWidget] with [RouteControl]. 
- [TickerControl] - mixin for [ControlWidget], enables Ticker for given Widget.

- [DisposeHandler] - mixin for any class, helps with object disposing.
- [PrefsProvider] - mixin for any class, helps to store user preferences.

---

**Helpers**

- [FutureBlock] Retriggerable delay.
- [DelayBlock] Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.
- [Parse] Helps to parse json primitives and Iterables. Also helps to look up Lists and Maps for objects.
- [WidgetInitializer] Helps to initialize Widgets with init data.
- [UnitId] Unique ID generator based on Time, Index or just Random. 

- and more..

---

**Example**

Control and App initialization. TodoController is initialized and stored in global [ControlFactory].
```dart
   class MainApp extends StatelessWidget {
     @override
     Widget build(BuildContext context) {
       return ControlBase(
         entries: {
           'todo': TodoController(),
         },
         root: (context) => TodoPage(),
         app: (context, key, home) => MaterialApp(
            key: key,
            home: home,
            title: 'Flutter Control',
         ),
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
  
  void onInit([Map args])
  {
    super.onInit(args);
    
    items.subscribe((list) => _recalculateCount());
    input.done(addInputItem);
    BroadcastProvider.subscribe<TodoItemModel>('remove', (value) => removeItem(value));
  }

  void addInputItem() {
    if (!input.validate()) {
      input.setError('invalid value');
      return;
    }

    final item = TodoItemModel(input.value);
    item.done.subscribe((value) => _recalculateCount());
    items.add(item);

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

Model holds state of one item in list and via BoolControl subscription notifies parent controller about changes.
```dart
class TodoItemModel extends BaseModel {
  final done = BoolControl();
  final String title;

  TodoItemModel(this.title);
  
  void removeSelf() => BroadcastProvider.broadcast<TodoItemModel>('remove', this);

  @override
  void dispose() {
    done.dispose(); // will also dispose Subscription
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

**Full Structure**

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure.png)