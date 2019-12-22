[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://cirrus-ci.com/github/RomanBase/flutter_control)

---

Flutter Control is complex library to maintain App and State management.\
Helps to separate Business Logic from UI and with Communication, Localization, Routing and passing arguments/values/events around.

---

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure_simple.png)

---

**Flutter Control Base**

- **[ControlBase]** Wraps App and initializes main Control classes with Global State, Factory and Localization. It's just shortcut to start with Flutter Control.
- **[ControlFactory]** Initializes and can store Controllers, Models and other objects. Dependency Injection is provided during initialization and also on demand.\
  Factory has own Storage. Objects in this storage are accessible via custom **key** or **Type**.\
  Comes with **[ControlProvider]** to easily access core functions from any part of App.\
  Factory is one and only singleton in this library.\
  Core objects of Flutter Control are stored in Factory Storage by default and are accessible by their **[Type]**.
  
---  

- **[BaseControlModel]** is base class to maintain Business Logic parts of App.
  **[BaseController]** Extended version of [BaseControlModel] with more functionality. Mainly used for pages or complex Widgets and also to separate robust Logic parts.
  **[BaseModel]** Extended but lightweight version of [BaseControlModel]. Mainly used for Items in dynamic List or to separate/reuse Logic parts.\
  This Controllers comes with few **[mixin]** classes to extend base functionality:
   - **[RouteController]** to provide navigation outside of Widget.\
   - **[StateController]** to notify state of whole Widget.\

- **[ControlWidget]** is base abstract class (**StatefulWidget**) to maintain UI parts of App. Widget is created with default **[ControlState]** to correctly reflect lifecycle of Widget to Models and Controllers. So there is no need to create custom [State].\
  If used correctly, this Widget will Init all containing Controllers and pass arguments to these Controllers.\
  This Widget comes with few **[mixin]** classes:
   - **[RouteControl]** to abstract navigation and easily pass arguments and init other Pages.
   - **[TickerControl]** and **[SingleTickerControl]** to create [State] with [Ticker] and provide access to **[vsync]**.
   
  **[SingleControlWidget]** is used to work with one Controller. This controller can be passed through constructor/init **[args]** or grabbed from [ControlFactory].\
  **[BaseControlWidget]** is used when there is no need to construct Controllers. Controllers still can be passed through constructor or init **[args]**.

```dart

```

---

- **[ActionControl]** is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has three variants - **Single** (just one listener), **Broadcast** (multiple listeners) and **Broadcast Listener** (subscribes to Global Event Stream).\
  On the Widget side is **[ControlBuilder]** to dynamically build Widgets. It's also possible to use **[ControlBuilderGroup]** for multiple Observables.\
  Value is set directly, but can be used privately and with **[ActionControlSub]** interface provide subscription functionality to public.\
  Upon dismiss every **[ControlSubscription]** is closed.

- **[FieldControl]** is more robust Observable solution around **[Stream]** and **[StreamController]**. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen **[Stream]**, **[Future]** or subscribe to another FieldControl with possibility to filter and convert values.\
  FieldControl comes with pre-build primitive variants as **[StringControl]**, **[DoubleControl]**, etc., where is possible to use validation, regex or value clamping. And also **[ListControl]** to work with Iterables.\
  On the Widget side is **[FieldBuilder]** and **[FieldStreamBuilder]** to dynamically build Widgets. Also **[FieldBuilderGroup]** for use with multiple Observables.\
  It's possible to set value directly, via **[FieldSink]** or **[FieldSinkConverter]**.\
  Upon dismiss every **[FieldSubscription]** is closed.

```dart

```

---
  
- [BaseLocalization] Json based localization, that supports simple strings, plurals and dynamic structures.
  Easy access via [LocalizationProvider] mixin. Localization object is stored in Factory, so is accessible without context and can be used even in Controllers, Entities, etc.
  
- [ControlBroadcast] Event stream across whole App. Broadcaster is part of [ControlFactory] and is stored there.
  With [BroadcastProvider] is possible to subscribe to any stream and send data or events from one end of App to another, even to Widgets.

---

**Controllers**

- [InputControl] Controller for [InputField] to control text, changes, validity, focus, etc. Controllers can be chained via 'next' and 'done' events.
- [NavigatorController] Controller for [NavigatorStack.single] to control navigation inside Widget.
- [NavigatorStackController] Controller for [NavigatorStack.pages] or [NavigatorStack.menu] to control navigation between pages. Mainly used with bottom menu.

---

**Widgets**

- [InputField] Wrapper of [TextField] to provide more functionality and control via [InputController].
- [StableWidget] Widget that is build just once. No mather how many times is build called. Rebuild can be forced via parameters..

- [NavigatorStack.single] Enables navigation inside Widget.
- [NavigatorStack.pages] Enables navigation between Widgets. Usable for menus, tabs, etc.
- [NavigatorStack.menu] Same as 'pages', but Widgets are generated from [MenuItem] data.

---

**Providers with static functionality**

- [BroadcastProvider] Globally broadcasts events and data.
- [ThemeProvider] Initializes [ControlTheme] and caches current [ThemeData].

---

**Routing**

- [PageRouteProvider] Specifies Route and WidgetBuilder settings for [RouteHandler]. With [WidgetInitializer] passing args to Widgets and Controllers during navigation.
- [RouteNavigator] Interface to work with Navigator and Routes.

---

**Mixins**

- [LocalizationProvider] - mixin for any class, enables [BaseLocalization] for given object.
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