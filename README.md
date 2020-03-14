[![Structure](https://api.cirrus-ci.com/github/RomanBase/flutter_control.svg)](https://cirrus-ci.com/github/RomanBase/flutter_control)

---

Flutter Control is complex library to maintain App and State management.\
Helps to separate Business Logic from UI and with Communication, Localization, Routing and passing arguments/values/events around.

 - **State Management** - UI / Logic separation
 - **Dependency Injection**
 - **Navigation and Routing**
 - **Localization**
 - **Event System**

---

Simplified structure of **core** classes in Flutter Control. Full diagram is at bottom of this page..
![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure_simple.png)

---

**Flutter Control Core**
- **[Control]** 
- **[ControlRoot]** Wraps App and initializes [Control]. It's just shortcut to start with Flutter Control. Via [ControlScope] is possible to maintain [State] of this root widget and control whole app state (localization, theme, etc.).
- **[ControlFactory]** Initializes and can store Controls, Models and other objects. Dependency Injection is provided during object initialization and also on demand.\
  Factory has own Storage. Objects in this storage are accessible via custom **key** or **Type**. Best practice is to use type as a key..\
  Comes with **[ControlProvider]** a class to easily access core functions from any part of App. Provider has two parts - Static and Widget.
  With static part is possible to 'get', 'set', 'init' and 'inject' objects. Widget part is StatelessWidget that provides object from Factory.\
  Factory is one and only singleton in this library.\
  Core objects of Flutter Control are stored in Factory Storage by default and are accessible by their **[Type]** or via Providers.
  
```dart
    //TODO: sample
```
  
---  

- **[ControlModel]** is base class to maintain Business Logic parts of App.\
  **[BaseControl]** is extended version of [ControlModel] with more functionality. Mainly used for pages or complex Widgets and also to separate robust Logic parts.\
  **[BaseModel]** is extended but lightweight version of [ControlModel]. Mainly used for Items in dynamic List or to separate/reuse Logic parts.\
  This Controls comes with few **[mixin]** classes to extend base functionality:
   - **[RouteControlProvider]** to provide navigation outside of Widget.
   - **[StateControl]** to notify state of whole Widget.
   - **[TickerComponent]** passes [Ticker] to Model.

- **[ControlWidget]** is base abstract class (**StatefulWidget**) to maintain UI parts of App. Widget is created with default **[ControlState]** to correctly reflect lifecycle of Widget to Models and Controls. So there is no need to create custom [State].\
  If used correctly, this Widget will Init all containing Controls and pass arguments to these Controllers.\
  This Widget comes with few **[mixin]** classes:
   - **[RouteControl]** to abstract navigation and easily pass arguments and init other Pages.
   - **[TickerControl]** and **[SingleTickerControl]** to create [State] with [Ticker] and provide access to **[vsync]**.
   
  **[SingleControlWidget]** is used to work with one Controller. This controller can be passed through constructor/init **[args]** or grabbed from [ControlFactory].\
  **[BaseControlWidget]** is used when there is no need to construct Controllers. Controllers still can be passed through constructor or init **[args]**.

```dart
  //TODO: sample
```

---

- **[ActionControl]** is one type of Observable used in this Library. It's quite lightweight and is used to notify Widgets and to provide events about value changes.\
  Has three variants - **Single** (just one listener), **Broadcast** (multiple listeners) and **Broadcast Listener** (subscribes to Global Broadcaster).\
  On the Widget side is **[ActionBuilder]** to dynamically build Widgets. It's also possible to use **[ActionBuilderGroup]** for multiple Observables.\
  Value is set directly, but can be used privately and with **[ActionControlSub]** interface provide subscription functionality to public.\
  Upon dismiss every **[ControlSubscription]** is closed.

- **[FieldControl]** is more robust Observable solution around **[Stream]** and **[StreamController]**. Primarily is used to notify Widgets and to provide events about value changes.\
  Can listen **[Stream]**, **[Future]** or subscribe to another FieldControl with possibility to filter and convert values.\
  FieldControl comes with pre-build primitive variants as **[StringControl]**, **[DoubleControl]**, etc., where is possible to use validation, regex or value clamping. And also **[ListControl]** to work with Iterables.\
  On the Widget side is **[FieldBuilder]** and **[FieldStreamBuilder]** to dynamically build Widgets. Also **[FieldBuilderGroup]** for use with multiple Observables.\
  It's possible to set value directly, via **[FieldSink]** or **[FieldSinkConverter]**.\
  Upon dismiss every **[FieldSubscription]** is closed.

```dart
    //TODO: sample
```

After hitting **'+'** button State of FieldBuilder will be notified and only Text Widget is re-build.

---

There is more ways how to pass and init Controllers in **[ControlWidget]** and listen about [State] lifecycle.

1. Constructor: we can pass Controllers as arguments with other **[args]**.
```dart
  //TODO: sample
```

2. Lazy load: Construct them manually or from Factory by overriding **[initControllers]**.
```dart
  //TODO: sample
```

3. Pass them via **[Initializable]** interface. This method is same as Constructor **[args]**. Both methods can be combined with different arguments.\
  **[init]** is also called by **[RouteControl]**, when passing arguments from one page to another.
```dart
  //TODO: sample
```

4. On demand during build statically or via Provider Widget, and new **[args]** can be pushed to objects:
```dart
  //TODO: sample
```

Arguments are then passed into Controllers as a **[Map]**. So you need to know **'key'** or **'Type'** to retrieve them. Static class **[Parse]** and their extensions can help..
  
```dart
  //TODO: sample
```

**[BaseControl]** by default prevents **'multi init'**. But this behaviour can be of course overridden.

---

**Other Important classes**
  
- **[BaseLocalization]** Json based localization, that supports simple strings, plurals and dynamic structures.\
  Easy access via **[LocalizationProvider]** mixin. Localization object is stored in Factory, so is accessible without context and can be used even in Controllers, Entities, etc.\
  Localization is initialized and loaded in **[Control]** by default.\
  And by default **[ControlWidget]** uses this localization.
  
```dart
  //TODO: sample
```
  
- **[ControlBroadcast]** Event stream across whole App. Broadcaster is part of **[ControlFactory]** and is stored there.\
  With **[BroadcastProvider]** is possible to subscribe to any stream and send data or events from one end of App to another, even to Widgets.

```dart
  //TODO: sample
```

- **[ControlTheme]** wraps **[ThemeData]**, **[MediaQuery]** into **[Device]** class and **[AssetPath]**.\
  **Theme** is cached on their first use, so **'Theme.of'** is called just once per Widget.\
  Control Theme adds some parameters and getters on top of standard Theme.\
  Easy access via **[ThemeProvider]** a mixin class that initializes **[ControlTheme]**.\
  Custom **[ControlTheme]** class builder can be used in [ControlBase] constructor to modify default params and provide more of them.

```dart
  //TODO: sample
```

---

- **[PageRouteProvider]** Specifies Route and WidgetBuilder settings for **[RouteHandler]**. With **[WidgetInitializer]** passing **[args]** to Widgets and Controllers during navigation.\
  Use **[RouteControl]** mixin to enable this navigation in Widget.

```dart
  //TODO: sample
```

Sometimes is handy to navigate from Controller or Model and for these scenarios exists **[RouteController]** mixin.\
Widget still needs to be implemented with **[RouteControl]**.

```dart
  //TODO: sample
```

---

**Other classes**

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

**Full Core Structure**

![Structure](https://raw.githubusercontent.com/RomanBase/flutter_control/master/doc/structure.png)