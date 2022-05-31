![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://cirrus-ci.com/github/RomanBase/flutter_control)


---

Flutter Control is complex library to maintain App and State management.\
Library merges multiple functionality under one hood. This approach helps to tidily bound separated logic into complex solution.

```dart
import 'package:flutter_control/control.dart';
```

 - **App State Management** - Managing application state, localization, theme and other global App changes.
 - **Widget State Management** - UI / Logic separation. Controlling State and UI updates.
 - **Dependency Injection** - Factory, Singleton, Lazy initialization and Service Locator.
 - **Navigation and Routing** - Routes, transitions and passing arguments to other pages and Models.
 - **Localization** - Json based localization with basic formatting.
 - **Event System** - Global event/data stream to easily notify app events.

---

**Flutter Control Core**
- `Control` Main static class. Initializes `ControlFactory` and provides easy access to most of core [Control] objects like `BaseLocalization`, `RouteStore`, `ControlBroadcast`, etc..
- `ControlFactory` Initializes and can store Controls, Models and other Objects. Works as Service Locator and Storage.\
  Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use Type as a key.\
  Factory is one and only Singleton in this Library.\
  Core objects of Flutter Control are stored in Factory's Storage by default (`Control.initControl`) and are accessible by their `Type` or via Providers.
  
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/service_locator.png)
  
```dart
    Control.initControl(
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
      modules: [
        LocalinoModule(LocalinoConfig(
          defaultLocale: 'en',
          locales: LocalinoAsset.map(locales: ['en_US', 'es_ES']),
          )),
      ],
      initAsync: () async {
        loadPreAppConfig();
      },
    );
```

- `ControlRoot` Wraps basic app flow and initializes [Control]. It's just shortcut to start with Flutter Control. Via `ControlScope` is possible to maintain `State` of this root widget and control whole app state (localization, theme, etc.).\
  Additionally offers App State management - home screen, localization and theme changes.

```dart
    ControlRoot(
      localization: LocalinoConfig(locales: [...]),
      theme: ThemeConfig<MyThemne>(
        builder: (context) => MyTheme(context),
        themes: {...},
      ),
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

- `ControlWidget` is base abstract class (**StatefulWidget**) to maintain larger UI parts of App (Pages or complex Widgets). Widget is created with default `ControlState` to correctly reflect lifecycle of Widget to Models. So there is no need to create custom [State].\
  Widget will **init** all containing Models and pass arguments to them.\
  `ControlWidget` is **immutable** so all logic parts (even UI logic and animations) must be controlled from outside. This helps truly separate all **code** from pure UI (also helps to reuse this code).
   
- `SingleControlWidget` is focused to single **ControlModel**. But still can handle multiple Controls.

- `ControllableWidget` - Subscribes to one or more `Observable` - [ObservableComponent], [ActionControl], [FieldControl], [Stream], [Future], [Listenable]\
  Whenever state of [ControlObservable] is changed, this Widget is rebuild.

  These Widgets comes with few `mixin` classes:
   - `RouteControl` to abstract navigation and easily pass arguments to Routes and init other Pages.
   - `TickerAnimControl`, `TickerControl` and `SingleTickerControl` to create [State] with `Ticker` and provide access to `vsync`.
   - `LocalizationProvider`, `ThemeProvider`, `OnLayout`, `ControlsComponent`, `OverlayControl` and more..
   
- `ControlModel` is base class to maintain Business Logic parts.\
  `BaseControl` is extended version of [ControlModel] with more functionality. Mainly used for robust Logic parts.\
  `BaseModel` is extended but lightweight version of [ControlModel]. Mainly used to control smaller logic parts.\
  This Controls comes with few `mixin` classes to extend base functionality:
   - `ObservableComponent` to control State and notify Widget about changes. Mostly used with `BaseModel`
   - `TickerComponent` passes `Ticker` to Model and enables to control animations outside of Widget.

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/states_events.png)

- `ControlObservable` and `ControlSubscription` are core underlying observable system and abstract base for other concrete robust implementations - mainly [ActionControl] and [FieldControl].\
  With `ControlBuilder` and `ControlBuilderGroup` on the Widget side. These universal builder widgets can handle all possible types of Notifiers.

- `ActionControl` is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has two variants - **Single** (just one listener), **Broadcast** (multiple listeners).\
  On the Widget side is `ControlBuilder` to dynamically build Widgets. It's also possible to use `ControlBuilderGroup` to group values of multiple Observables.\
  Upon dismiss of [ActionControl], every `ControlSubscription` is closed.

```dart
    final counter = ActionControl.broadcast<int>(0);

    ActionBuilder<int>(
      control: counter,
      builder: (context, value) => Text(value.toString()),
    );
```

- `FieldControl` is more robust Observable solution around `Stream` and `StreamController`. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen `Stream`, `Future` or subscribe to another [FieldControl] with possibility to filter and convert values.\
  [FieldControl] comes with pre-build primitive variants as `StringControl`, `NumberControl`, etc., where is possible to use validation, regex or value clamping. And also `ListControl` to work with Iterables.\
  On the Widget side is `FieldBuilder` and `ControlBuilder` to dynamically build Widgets. Also `ControlBuilderGroup` for use with multiple Observables. It's also possible to use standard `StreamBuilder`.\
  `FieldSink` or `FieldSinkConverter` provides **Sink** of [FieldControl].\
  Upon dismiss of [FieldControl], every `FieldSubscription` is closed.

```dart
    final counter = FieldControl<int>(0);

    FieldBuilder<int>(
      control: counter,
      builder: (context, value) => Text(value.toString()),
    );
```
  Check [Counter Example](https://github.com/RomanBase/flutter_control/tree/master/examples/a_counter) and [TODO List Example](https://github.com/RomanBase/flutter_control/tree/master/examples/b_todo_list) at Git repository.

---

Structure below shows how data and events flows between UI and Controls. `ControlWidget` can use multiple `ControlModel`s with multiple Models, Streams and Observables..
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/architecture_flow.png)

---

**Localization**
  
- `BaseLocalization` Json based localization, that supports simple strings, plurals and dynamic structures.\
  Easy access via `LocalizationProvider` mixin. Localization object is stored in [ControlFactory], so is accessible without context and can be used even in Models, Entities, etc. via `Control.localization()`\
  Localization is initialized and loaded in `Control` by default.\
  And by default `ControlWidget` uses this localization via mixin.
  
```dart
    Control.initControl(
      localization: LocalizationConfig(
        defaultLocale: 'en',
        locales: {
          'en': 'assets/localization/en.json',
          'es': 'assets/localization/es.json',
        },
      ),
    );
```

```dart
    ControlRoot(
      localization: LocalizationConfig(
        locales: {
          ...LocalizationAsset.map(locales: ['en_US', 'es_ES']),
        },
      ),
    );
```
  Check [Localization Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization) and [Localization Delegate Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization_delegate) at Git repository.

**Global Event System**  
  
- `ControlBroadcast` Event stream across whole App. Default broadcaster is part of `ControlFactory` and is stored there.\
  Every subscription is bound to it's `key` and `Type` so notification to Listeners arrives only for expected data.\
  With `BroadcastProvider` is possible to subscribe to any stream and send data or events from one end of App to the another, even to Widgets and their States.
  Also custom broadcaster can be created to separate events from global/default stream.

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/broadcaster.png)

```dart
  BroadcastProvider.subscribe<int>('on_count_changed', (value) => updateCount(value));
  BraodcastProvider.broadcast('on_count_changed', 10);
```

**Navigation and Routing**

- `ControlRoute` Specifies `Route` with `Transition` and [WidgetBuilder] for `RouteHandler`. Handler then solves navigation and passes **args** to Widgets and Models.\
  Use `RouteControl` mixin to enable this navigation with [ControlWidget] and `RouteControlProvider` mixin with [ControlModel].
  Routes can be stored in `RouteStore` and Route builder is accessible statically via `ControlRoute.of`.

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
        onPressed: () => routeOf<DetailPage>().openRoute();
        onPressed: () => routeOf<DetailPage>().viaTransition(_transitionBuilder).openRoute();
        onPressed: () => routeOf(key: 'detail_super').openRoute();
        ...
      };
    }
```
  Check [Navigation Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation) and [Navigation Stack Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation_stack) at Git repository.

---

**Other classes**

- `ControlTheme` and `ThemeProvider` Wraps [ThemeData], [MediaQuery] and asset path helper.
- `InputField` Wrapper of [TextField] to provide more functionality and control via `InputControl`.
- `DisposeHandler` - mixin for any class, helps with object disposing.
- `PrefsProvider` - mixin for any class, helps to store user preferences - based on [shared_preferences](https://pub.dartlang.org/packages/shared_preferences).
- `Parse` Helps to parse json primitives and Iterables. Also helps to look up Lists and Maps for objects.
- `FutureBlock` Retriggerable delay.
- `DelayBlock` Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.
- `WidgetInitializer` Helps to initialize Widgets with init data.
- `UnitId` Unique Id generator based on Time, Index or just Random. 

- and more..

---

Check set of [Flutter Control Examples](https://github.com/RomanBase/flutter_control/tree/master/examples) at Git repository for more complex solutions and how to use this library.