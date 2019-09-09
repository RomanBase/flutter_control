## [0.9.3] - RouteControl, NavigatorStack
## [0.9.1] - Dependency update
## [0.8.98] - Control Group Builders
## [0.8.96] - Flutter 1.7 support
## [0.8.5] - Alpha version

---

**Base classes**

- [BaseApp] Wraps MaterialApp and initializes Control and Factory. It's just shortcut to start with Flutter Control.
- [AppControl] Is [InheritedWidget] around whole App. Holds Factory and other important Controllers.
- [ControlFactory] Mainly initializes and stores Controllers, Models and other Logic classes. Also works as global Stream to provide communication and synchronization between separated parts of App.
- [BaseLocalization] Json based localization, that supports simple strings, plurals and dynamic structures.
- [RouteHandler] Initializes Widget and handles Navigation.

---

**Streams**

- [ActionControl] Single or Broadcast Observable. Usable with [ControlBuilder] to dynamically build Widgets.
- [FieldControl] Stream wrapper to use with [FieldStreamBuilder] or [FieldBuilder] to dynamically build Widgets.
- [ListControl] Extended FieldControl to work with [List]
- [RxControl] under construction..

---

**Controllers**

- [BaseController] Stores all Business Logic and initializes self during Widget construction. Have native access to Factory and Control.
- [StateController] Adds functionality to notify State of [ControlWidget].
- [BaseModel] Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.
- [InputController] Controller for [InputField] to control text, changes, validity, focus, etc. Controllers can be chained via 'next' and 'done' events.
- [NavigatorController] Controller for [NavigatorStack.single] to control navigation inside Widget.
- [NavigatorStackController] Controller for [NavigatorStack.pages] or [NavigatorStack.menu] to control navigation between Widgets.

---

**Widgets**

- [ControlWidget] Base Widget to work with Controllers. Have native access to Factory and Control. 
- [BaseControlWidget] Widget with no init Controllers, but still have access to Factory etc. so Controllers can be get from there.
- [SingleControlWidget] Widget with just one generic Controller.

- [InputField] Wrapped [TextField] to provide more functionality and control via [InputController].
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
- [RouteControl] - mixin for [ControlWidget], enables route navigation.
- [RouteController] - mixin for [BaseController], enables route navigation bridge to [ControlWidget] with [RouteControl]. 
- [TickerControl] - mixin for [ControlWidget], enables Ticker for given Widget.

- [DisposeHandler] - mixin for any class, helps with object disposing.
- [PrefsProvider] - mixin for any class, helps to store user preferences.

---

**Helpers**

- [FutureBlock] Retriggerable delay.
- [DelayBlock] Delay to wrap a block of code to prevent 'super fast' completion and UI jiggles.
- [Parse] Helps to parse json primitives and Iterables. Provides default values if parsing fails.
- [ArgProvider] Helps to retrieve object form List or Map.
- [Device] Wrapper over [MediaQuery].
- [WidgetInitializer] Helps to initialize Widgets with init data.
- [BaseTheme] Some basic values to work with during Widget composition.

- and more..

---
