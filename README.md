![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/logo.png)

[![Structure](https://github.com/RomanBase/flutter_control/actions/workflows/dart.yml/badge.svg)](https://github.com/RomanBase/flutter_control)


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
- `Control` Main static class. Initializes `ControlFactory` that serves as Service Locator with Factory and object initialization.
- `ControlFactory` Is responsible for creating and storing given `factories` and `entries`. Then locating this services and retrieving on demand.\
  Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use Type as a key.
- `ControlModule` holds all resources for custom extension. Factory will load these `modules` and stores dependencies.

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
      modules: [
        LocalinoModule(LocalinoLive.options()),
      ],
      initAsync: () async {
        loadAppConfig();
      },
    );
```

- `ControlRoot` Wraps basic app flow and global state management - Theme, Locale, Home Widget. It's just shortcut to start with Flutter Control.

```dart
    ControlRoot(
      theme: MaterialThemeConfig(
        themes: {
          Brightness.light: () => ThemeData.light(),
          Brightness.dark: () => ThemeData.dark(),
        }
      ),
      states: [
        AppState.init.build(builder: (_) => LoadingPage()),
        AppState.main.build(
          builder: (_) => DashboardPage(),
          transition: TransitionToDashboard(),
        ),
      ],
      builders: [
        Localino,
      ],
      app: (context, home) => MaterialApp(
        title: setup.title('app_name', 'Example App'),
        theme: context.themeConfig?.value,
        home: home,
        locale: LocalinoProvider.instance.currentLocale,
        supportedLocales: setup.supportedLocales,
        localizationsDelegates: [
          ...
        ],        
      ),
    );
```

---

- `ControlWidget` is base abstract class (**StatefulWidget**) to maintain larger UI parts of App (Pages and complex Widgets). Widget is created with default `ControlState` to correctly reflect lifecycle of Widget to Models. So there is no need to create custom [State].\
  Widget will **init** all containing Models and pass arguments to them.\
  `ControlWidget` has mutable State to control state management.
   
- `SingleControlWidget` is focused to single **ControlModel**. But still can handle multiple Controls.

- `ControllableWidget` - Subscribes to one or more `Observable` - [ObservableComponent], [ActionControl], [FieldControl], [Stream], [Future], [Listenable]\
  Whenever state of [ControlObservable] is changed, this Widget is rebuild.
   
- `ControlModel` is base class to maintain Business Logic parts.\
  `BaseControl` is extended version of [ControlModel] with more functionality. Mainly used for robust Logic parts.\
  `BaseModel` is extended but lightweight version of [ControlModel]. Mainly used to control smaller logic parts.\

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/states_events.png)

- `ControlObservable` and `ControlSubscription` are core underlying observable system and abstract base for other concrete robust implementations - mainly [ActionControl] and [FieldControl].\
  With `ControlBuilder` and `ControlBuilderGroup` on the Widget side. These universal builder widgets can handle all possible types of Notifiers.

- `ActionControl` is one type of Observable used in this Library. It's quite lightweight and is used to notify listeners about value changes.\
  Has tree main variants - **Single** (just one listener), **Broadcast** (multiple listeners) and **Empty** (null).\
  4th variant is **provider** that subscribe to global [BroadcastProvider].\
  On the Widget side is `ControlBuilder` to dynamically build Widgets. It's also possible to use `ControlBuilderGroup` to group values of multiple Observables.\
  Upon dismiss of [ActionControl], every `ControlSubscription` is closed.

```dart
    final counter = ActionControl.broadcast<int>(0);

    ControlBuilder<int>(
      control: counter,
      builder: (context, value) => Text('$value'),
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

---

Structure below shows how data and events flows between UI and Controls. `ControlWidget` can use multiple `ControlModel`s with multiple Models, Streams and Observables..
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/architecture_flow.png)

---

**Localization**

- Moved to [Localino](https://pub.dev/packages/localino) package.

**Global Event System**  
  
- `ControlBroadcast` Event stream across whole App. Default broadcaster is part of `ControlFactory` and is stored there.\
  Every subscription is bound to it's `key` and/or `Type` so notification to Listeners arrives only for expected data.\
  With `BroadcastProvider` is possible to subscribe to any stream and send data or events from one end of App to the another, even to Widgets and their States.
  Also custom broadcaster can be created to separate events from default stream.

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/broadcaster.png)

```dart
  BroadcastProvider.subscribe<int>('on_count_changed', (value) => updateCount(value));
  BraodcastProvider.broadcast('on_count_changed', 10);
```

**Navigation and Routing**

- `ControlRoute` Specifies `Route` with `Transition` and [WidgetBuilder] for `RouteHandler`. Handler then solves navigation and passes **args** to Widgets and Models.\
  Use `Dependency` mixin to enable this argument injection into [ControlWidget].
- Routes are stored in `RouteStore`.

```dart
    Control.initControl(
      modules: [
        RoutingModule(
          [
            ControlRoute.build<DetailPage>(builder: (_) => DetailPage()),
            ControlRoute.build(key: 'detail_super', builder: (_) => DetailPage()).path('super').viaTransition(_transitionBuilder),  
          ]
        );
      ],
    );

    class ListPage extends ControlWidget with RouteControl {
      Widget build(CoreContext context){
        ...
        onPressed: () => context.routeOf<DetailPage>().openRoute();
        onPressed: () => context.routeOf<DetailPage>().viaTransition(_transitionBuilder).openRoute();
        onPressed: () => context.routeOf(key: 'detail_super').openRoute();
        ...
      };
    }
```

- Initial app routing is handled with `RoutingProvider`, that stores initial route for later use (after app is initialized, auth confirmed, etc.).

```dart
  ControlRoot(
    builder(context, home) => MaterialApp(
      onGenerateRoute: (settings) => context.generateRoute(settings, root: () => MaterialPageRoute(builder: (_) => home)),
    )
  );

  class HomePage extends ControlWidget {
    void onInit(CoreContext context, Map args){
      //Restores initial route navigation from from onGenerateRoute 
      context.root.restoreNavigation();
    } 
  }
```
---

**Other classes**

- `DisposeHandler` - mixin for any class, helps with object disposing.
- `PrefsProvider` - mixin for any class, helps to store user preferences - based on [shared_preferences](https://pub.dartlang.org/packages/shared_preferences).
- `Parse` Helps to parse json primitives and Iterables. Also helps to look up Lists and Maps for objects.
- `FutureBlock` Retriggerable delay.
- `DelayBlock` Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.

---

Check set of [Flutter Control Examples](https://github.com/RomanBase/flutter_control/tree/master/example) at Git repository for more complex solutions and how to use this library.
More examples comes in future..