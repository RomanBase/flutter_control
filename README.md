[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://cirrus-ci.com/github/RomanBase/flutter_control)

---

Flutter Control is complex library to maintain App and State management.\
Library merges multiple functionality under one hood. This approach helps to tidily bound separated logic into complex solution.

 - **State Management** - UI / Logic separation (inspired by BLoC).
 - **Dependency Injection** - Factory, Singleton and Lazy initialization.
 - **Navigation and Routing** - Routes, transitions and passing arguments to other pages and controls.
 - **Localization** - Json based localization with basic formatting.
 - **App Broadcast** - Global event/data stream to easily notify app events. 

---

Simplified structure of **core** classes in Flutter Control. Full diagram is at bottom of this page.\
**[Control]** with **[ControlFactory]** is main gate and bounds everything together.\
**[ControlWidget]** holds UI and **[ControlModel]** solves Business Logic.
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure_simple.png)

---

**Flutter Control Core**
- **[Control]** Main static class. Initializes **[ControlFactory]** and provides easy access to most of core [Control] objects like **[BaseLocalization]**, **[RouteStore]**, **[ControlBroadcast]**, etc..
- **[ControlFactory]** Initializes and can store Controls, Models and other objects. Dependency Injection is provided during object initialization and also on demand.\
  Factory has own **Storage**. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use type as a key..\
  Comes with **[Control]** a class to easily provide core functions from any part of App. Via static functionality is possible to 'get', 'set', 'init' and 'inject' objects.\
  Factory is one and only singleton in this library.\
  Core objects of Flutter Control are stored in Factory's Storage by default (when factory is initialized via [Control]) and are accessible by their **[Type]** or via Providers.
 - **[ControlRoot]** Wraps App and initializes [Control]. It's just shortcut to start with Flutter Control. Via **[ControlScope]** is possible to maintain **[State]** of this root widget and control whole app state (localization, theme, etc.).
  
```dart
    //TODO: sample
```
  
---  

- **[ControlWidget]** is base abstract class (**StatefulWidget**) to maintain UI parts of App. Widget is created with default **[ControlState]** to correctly reflect lifecycle of Widget to Models and Controls. So there is no need to create custom [State].\
  Widget will **init** all containing Models and pass arguments to them.\
  [ControlWidget] is **immutable** so all logic parts (even UI logic and animations) must be controlled outside. This helps truly separate all **code** from pure UI (also helps to reuse this code).
  Also **[LocalizationProvider]** is part of this Widget and it's possible to fully use library's localization without delegate.
  This Widget comes with few **[mixin]** classes:
   - **[RouteControl]** to abstract navigation and easily pass arguments and init other Pages.
   - **[TickerControl]** and **[SingleTickerControl]** to create [State] with **[Ticker]** and provide access to **[vsync]**.
   
  **[SingleControlWidget]** is used to work with one Controller. This controller can be passed through constructor/init **[args]** or grabbed from [ControlFactory].\
  **[BaseControlWidget]** is used when there is no need to construct Controllers. Controllers still can be passed through constructor or init **[args]**.

- **[StateboundWidget]** under construction.

- **[ControlModel]** is base class to maintain Business Logic parts of App.\
  **[BaseControl]** is extended version of [ControlModel] with more functionality. Mainly used for pages or complex Widgets and also to separate robust Logic parts.\
  **[BaseModel]** is extended but lightweight version of [ControlModel]. Mainly used for Items in dynamic List or to separate/reuse Logic parts.\
  This Controls comes with few **[mixin]** classes to extend base functionality:
   - **[RouteControlProvider]** to provide navigation outside of Widget.
   - **[StateControl]** to control state of whole Widget.
   - **[TickerComponent]** passes **[Ticker]** to Model and enables to control animations outside of Widget.

---

- **[ActionControl]** is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has two variants - **Single** (just one listener), **Broadcast** (multiple listeners).\
  On the Widget side is **[ActionBuilder]** to dynamically build Widgets. It's also possible to use **[ActionBuilderGroup]** for multiple Observables.\
  Value is set directly, but property can be used privately and with **[ActionControlSub]** interface to provide subscription to public.\
  Upon dismiss every **[ControlSubscription]** is closed.

- **[FieldControl]** is more robust Observable solution around **[Stream]** and **[StreamController]**. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen **[Stream]**, **[Future]** or subscribe to another [FieldControl] with possibility to filter and convert values.\
  [FieldControl] comes with pre-build primitive variants as **[StringControl]**, **[DoubleControl]**, etc., where is possible to use validation, regex or value clamping. And also **[ListControl]** to work with Iterables.\
  On the Widget side is **[FieldBuilder]** and **[FieldStreamBuilder]** to dynamically build Widgets. Also **[FieldBuilderGroup]** for use with multiple Observables. It's also possible to use standard **[StreamBuilder]**.\
  Value is set directly, but property can bu used privately and to public provide just sink - **[FieldSink]** or **[FieldSinkConverter]** and stream - **[FieldControlSub]** interface to provide subscription to public.\
  Upon dismiss every **[FieldSubscription]** is closed.

---

```dart
    //TODO: sample
```
  Check [Counter Example](https://github.com/RomanBase/flutter_control/tree/master/examples/a_counter) and [TODO List Example](https://github.com/RomanBase/flutter_control/tree/master/examples/b_todo_list) at Git repository.

Structure below shows how data and events flows between UI and Model. **[ControlWidget]** can use multiple **[ControlModel]s** - for example one for Business Logic and one for UI/animation part.\
With this approach is really easy to reuse UI/animation logic on multiple widgets and mainly separate Business Logic of Models from UI.
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/architecture_flow.png)

---

**Other Important classes**
  
- **[BaseLocalization]** Json based localization, that supports simple strings, plurals and dynamic structures.\
  Easy access via **[LocalizationProvider]** mixin. Localization object is stored in Factory, so is accessible without context and can be used even in Models, Entities, etc.\
  Localization is initialized and loaded in **[Control]** by default.\
  And by default **[ControlWidget]** uses this localization.
  
```dart
  //TODO: sample
```
  Check [Localization Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization) and [Localization Delegate Example](https://github.com/RomanBase/flutter_control/tree/master/examples/c_localization_delegate) at Git repository.
  
- **[ControlBroadcast]** Event stream across whole App. Default broadcaster is part of **[ControlFactory]** and is stored there.\
  Every subscription is bound to it's **[key]** and **[Type]** so notification arrives only for expected data.\
  With **[BroadcastProvider]** is possible to subscribe to any stream and send data or events from one end of App to another, even to Widgets and their States.
  Also custom broadcaster can be created to separate events from global/default stream.

```dart
  //TODO: sample
```

- **[ControlTheme]** wraps **[ThemeData]**, **[MediaQuery]** into **[Device]** class and **[AssetPath]**.\
  **Theme** is cached on their first use, so **'Theme.of'** is called just once per Widget.\
  Control Theme adds some parameters and getters on top of standard Theme.\
  Easy access via **[ThemeProvider]** a mixin class that initializes **[ControlTheme]**.\
  Custom **[ControlTheme]** class builder can be used in [ControlRoot] constructor to modify default params and provide more of them.\
  **!!! [ControlTheme]** is not **const** so it can have impact to performance, but no issues has been reported yet.. 

---

- **[ControlRoute]** Specifies **[Route]** with **[Transition]** and [WidgetBuilder] settings for **[RouteHandler]**. With **[WidgetInitializer]** passing **[args]** to Widgets and Models during navigation.\
  Use **[RouteControl]** mixin to enable this navigation with Widget and **[RouteControlProvider]** mixin with [ControlModel].

```dart
  //TODO: sample
```
  Check [Navigation Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation) and [Navigation Stack Example](https://github.com/RomanBase/flutter_control/tree/master/examples/d_navigation_stack) at Git repository.

---

**Other util classes**

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