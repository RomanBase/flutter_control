[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://cirrus-ci.com/github/RomanBase/flutter_control)

---

Flutter Control is complex library to maintain App and State management.\
Library merges multiple functionality under one hood. This approach helps to tidily bound separated logic into complex solution.

 - **App State Management** - Managing application state, localization and theme changes.
 - **Widget State Management** - UI / Logic separation. Controlling State and UI updates.
 - **Dependency Injection** - Factory, Singleton and Lazy initialization.
 - **Navigation and Routing** - Routes, transitions and passing arguments to other pages and Models.
 - **Localization** - Json based localization with basic formatting.
 - **Event System** - Global event/data stream to easily notify app events.

---

Simplified structure of **core** classes in Flutter Control. Full diagram is at bottom of this page.\
**[Control]** with **[ControlFactory]** is main gate and bounds everything together.\
**[ControlWidget]** holds UI and **[ControlModel]** solves Business Logic.
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure_simple.png)

---

**Flutter Control Core**
- **[Control]** Main static class. Initializes **[ControlFactory]** and provides easy access to most of core [Control] objects like **[BaseLocalization]**, **[RouteStore]**, **[ControlBroadcast]**, etc..
- **[ControlFactory]** Initializes and can store Controls, Models and other objects. Dependency Injection is provided during object initialization and also on demand.\
  Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use Type as a key.\
  Factory is one and only singleton in this library.\
  Core objects of Flutter Control are stored in Factory's Storage by default ([Control.initControl]) and are accessible by their **[Type]** or via Providers.
- **[ControlRoot]** Wraps App and initializes [Control]. It's just shortcut to start with Flutter Control. Via **[ControlScope]** is possible to maintain **[State]** of this root widget and control whole app state (localization, theme, etc.).
  
```dart
    Control.initControl(
      localization: LocalizationConfig(
        defaultLocale: 'en',
        locales: LocalizationAsset.build(locales: ['en_US', 'es_ES']),
      ),
      entries: {
        CounterListControl: CounterListControl(),
      },
      initializers: {
        CounterModel: (_) => CounterModel(),
        CounterDetailControl: (args) => CounterDetailControl(model: Parse.getArg<CounterModel>(args)),
      },
      routes: [
        ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
      ],
      initAsync: () async {
        loadPreAppConfig();
      },
    );
```
  
**ControlRoot** additionally offers App State management - home scree, localization and theme changes.

```dart
    ControlRoot(
      localization: LocalizationConfig(locales: [...]),
      entries: {...},
      initializers: {...},
      routes: [...],
      states: [
        AppState.init.build(builder: (_) => LoadingPage()),
        AppState.main.build(
          builder: (_) => DashboardPage(),
          transition: TransitionToDashboard(),
        ),
      ],
      app: (setup, home) => MaterialApp(
        key: setup.key,
        title: setup.title('app_name', 'Example App'),
        theme: setup.theme,
        home: home,
        locale: setup.locale,
        supportedLocales: setup.supportedLocales,
        localizationsDelegates: [
          ...
        ],        
      ),
    );
```

---

- **[ControlWidget]** is base abstract class (**StatefulWidget**) to maintain larger UI parts of App (Pages or complex Widgets). Widget is created with default **[ControlState]** to correctly reflect lifecycle of Widget to Models. So there is no need to create custom [State].\
  Widget will **init** all containing Models and pass arguments to them.\
  [ControlWidget] is **immutable** so all logic parts (even UI logic and animations) must be controlled from outside. This helps truly separate all **code** from pure UI (also helps to reuse this code).
  Also **[LocalizationProvider]** is part of this Widget and it's possible to fully use library's localization without delegate.
  This Widget comes with few **[mixin]** classes:
   - **[RouteControl]** to abstract navigation and easily pass arguments and init other Pages.
   - **[TickerControl]** and **[SingleTickerControl]** to create [State] with **[Ticker]** and provide access to **[vsync]**.
   
  **[SingleControlWidget]** - Focused to single **ControlModel**. But still can handle multiple Controls.
  **[MountedControlWidget]** - Automatically uses all **ControlModels** passed to Widget.

- **[StateboundWidget]** - Subscribes to just one **[StateControl]** - a mixin class typically used with [ControlModel] - [BaseControl] or [BaseModel].\
  Whenever state of [ControlState] is changed, this Widget is rebuild.

- **[ControlModel]** is base class to maintain Business Logic parts of App.\
  **[BaseControl]** is extended version of [ControlModel] with more functionality. Mainly used for Pages or complex Widgets and also to separate robust Logic parts.\
  **[BaseModel]** is extended but lightweight version of [ControlModel]. Mainly used to control smaller Widgets like Items in dynamic List or to separate/reuse Logic parts.\
  This Controls comes with few **[mixin]** classes to extend base functionality:
   - **[RouteControlProvider]** to provide navigation outside of Widget.
   - **[StateControl]** to control state of whole Widget.
   - **[TickerComponent]** passes **[Ticker]** to Model and enables to control animations outside of Widget.

---

- **[ActionControl]** is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has two variants - **Single** (just one listener), **Broadcast** (multiple listeners).\
  On the Widget side is **[ActionBuilder]** to dynamically build Widgets. It's also possible to use **[ActionBuilderGroup]** to group values of multiple Observables.\
  **[ActionControlSub]** provides read-only version of ActionControl.\
  Upon dismiss of ActionControl, every **[ControlSubscription]** is closed.

```dart
    final counter = ActionControl.broadcast<int>(0);

    ActionBuilder<int>(
      control: counter,
      builder: (context, value) => Text(value.toString()),
    );
```

- **[FieldControl]** is more robust Observable solution around **[Stream]** and **[StreamController]**. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen **[Stream]**, **[Future]** or subscribe to another [FieldControl] with possibility to filter and convert values.\
  [FieldControl] comes with pre-build primitive variants as **[StringControl]**, **[DoubleControl]**, etc., where is possible to use validation, regex or value clamping. And also **[ListControl]** to work with Iterables.\
  On the Widget side is **[FieldBuilder]** and **[FieldStreamBuilder]** to dynamically build Widgets. Also **[FieldBuilderGroup]** for use with multiple Observables. It's also possible to use standard **[StreamBuilder]**.\
  Value is set directly, but property can bu used privately and to public provide just sink - **[FieldSink]** or **[FieldSinkConverter]** and stream - **[FieldControlSub]** interface to provide subscription to public.\
  Upon dismiss of FieldControl, every **[FieldSubscription]** is closed.

```dart
    final counter = FieldControl<int>(0);

    FieldBuilder<int>(
      control: counter,
      builder: (context, value) => Text(value.toString()),
    );
```
  Check [Counter Example](https://github.com/RomanBase/flutter_control/tree/master/examples/a_counter) and [TODO List Example](https://github.com/RomanBase/flutter_control/tree/master/examples/b_todo_list) at Git repository.

Structure below shows how data and events flows between UI and Model. **[ControlWidget]** can use multiple **[ControlModel]s** - for example one for Business Logic and one for UI/animation part.\
With this approach is really easy to reuse UI/animation logic on multiple widgets and mainly separate Business Logic of Models from UI.
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/architecture_flow.png)

---

**Other Important classes**
  
- **[BaseLocalization]** Json based localization, that supports simple strings, plurals and dynamic structures.\
  Easy access via **[LocalizationProvider]** mixin. Localization object is stored in Factory, so is accessible without context and can be used even in Models, Entities, etc. via **[Control.localization()]**\
  Localization is initialized and loaded in **[Control]** by default.\
  And by default **[ControlWidget]** uses this localization with mixin.
  
```dart
    Control.initControl(
      localization: LocalizationConfig(
        defaultLocale: 'en',
        locales: LocalizationAsset.build(locales: ['en_US', 'es_ES']),
      ),
    );
```

```dart
    ControlRoot(
      localization: LocalizationConfig(
        locales: {
          'en': 'assets/localization/en.json',
          'es': 'assets/localization/es.json',
        },
      ),
    );
```
  Check [Localization Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization) and [Localization Delegate Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization_delegate) at Git repository.
  
- **[ControlBroadcast]** Event stream across whole App. Default broadcaster is part of **[ControlFactory]** and is stored there.\
  Every subscription is bound to it's **[key]** and **[Type]** so notification arrives only for expected data.\
  With **[BroadcastProvider]** is possible to subscribe to any stream and send data or events from one end of App to another, even to Widgets and their States.
  Also custom broadcaster can be created to separate events from global/default stream.

```dart
  BroadcastProvider.subscribe<int>('on_count_changed', (value) => updateCount(value));
  BraodcastProvider.broadcast('on_count_changed', 10);
```

---

- **[ControlRoute]** Specifies **[Route]** with **[Transition]** and [WidgetBuilder] settings for **[RouteHandler]**. With **[WidgetInitializer]** passing **[args]** to Widgets and Models during navigation.\
  Use **[RouteControl]** mixin to enable this navigation with Widget and **[RouteControlProvider]** mixin with [ControlModel].
  Routes can be stored in **[RouteStore]** and initialized via [Control.initControl].

```dart
    Control.initControl(
      routes: [
        ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
        ControlRoute.build(key: 'detail_super', builder: (_) => DetailPage()).path('super').viaTransition(_transitionBuilder),
      ],
    );

    class ListPage extends ControlWidget with RouteControl {
      Widget build(BuildContext context){
        ...
        routeOf<DetailPage>().openRoute();
        routeOf<DetailPage>().viaTransition(_transitionBuilder).openRoute();
      };
    }
```
  Check [Navigation Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation) and [Navigation Stack Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation_stack) at Git repository.

---

**Other util classes**

- **[ControlTheme]** and **[ThemeProvider]** Wraps **ThemeData**, **MediaQuery** and asset path helper.
- **[InputField]** Wrapper of [TextField] to provide more functionality and control via [InputController].
- **[DisposeHandler]** - mixin for any class, helps with object disposing.
- **[PrefsProvider]** - mixin for any class, helps to store user preferences.
- **[FutureBlock]** Retriggerable delay.
- **[DelayBlock]** Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.
- **[Parse]** Helps to parse json primitives and Iterables. Also helps to look up Lists and Maps for objects.
- **[WidgetInitializer]** Helps to initialize Widgets with init data.
- **[UnitId]** Unique Id generator based on Time, Index or just Random. 

- and more..

---

Check set of [Flutter Control Examples](https://github.com/RomanBase/flutter_control/tree/master/examples) at Git repository for more complex solutions and how to use this library.

---

**Full Core Structure**

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure.png)