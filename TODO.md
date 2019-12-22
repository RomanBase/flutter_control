- Documentation
  + All.

- Tests
  + ControlWidget.
  + BaseLocalization.
  + RouteHandler.
  + WidgetInitializer.

- Examples
  + Default Flutter template.
  + Login Form with API call.
  + TODO List.
  + Localization example.
  + ListView and detail page.
  + Menu page.
  + Dialogs.
  + Navigation and custom Route/Transition.

- [Core] 'minor update'
  + **done** Add more platforms to 'onPlatform' function.

- [ControlApp] 'major update'
  + **done** Support for custom and any WidgetsApp. Wrap around whole App.
  + **done** Deprecate [BaseApp]
  
- [AppControl] 'new purpose update'
  + **done** Provide access to root elements of App.
  + **done** Notify whole App about rebuild.
  
- [ControlFactory] 'semi-major update'
  + **done** Merge or clean up some shady functions.
  + **done** 'add' vs. 'addItem' functions - 'object' to store is required and 'key' can be empty.
  + **done** 'get' vs. 'getWith' - can be merged.
  + **done** 'find' - make it more generic and use Parse/ArgHandler to help find object from input collection.

- [ControlWidget] 'semi-major update'
  + Better support for custom State
  + Provide more State functions - directly or via mixins, some of them can be binded even to Controller.
  + [WidgetControlHolder] - check build/hot reload, correct widget/state pairing, maybe more 'get' caching to holder to save some performance
  + [TickerControl] - better support for custom State
  + [RouteControl] - more dialog options and custom Transitions

- [ArgHandler] x [Parse] 'minor update'
  + **done** Deprecate ArgHandler and upgrade Parse with functions from ArgHandler.
  + **done** 'getArg' - accepts dynamic at input and decides what to do next - use getArgFrom List/Map or cast, use other parse method or return default..
  + **done** 'getArgFromList' - based on ArgHandler.list/ArgHandler.iterable
  + **done** 'getArgFromMap' - based on ArgHandler.map
  + **done** 'getArgFromString' - parse input to json and then return object.

- [GlobalSubscription] x [ControlSubscription] x [FieldSubscription] 'major update'
  + **nope** Compare these and maybe merge them or create interface/abstract class.

- [FieldControl] 'minor update'
  + **done** Provide save access to Stream or to major Stream functions.

- [ListControl] 'semi-major update'
  + **done** Implement whole Iterable or just major functions from there..
  
- [StringControl] 'minor update'
  + **done** Add regex validation

- [IntegerControl] and [DoubleControl] 'minor update'
  + **done** Update 'inRange' functionality to work within 'setValue'.
  
- [FieldBuilderGroup] 'minor update'
  + **done** Cancel subscriptions on dispose.
  
- [InputField] 'minor update'
  + **done** Check/correct params or default values for latest Flutter version.
  
- [NavigatorController] and [NavigatorStackController] 'minor update'
  + Provide functions to Controllers of child Widgets.
  
- [StableWidget] 'minor update'
  + It's too stable :) hot reload not working now..
  
- [Device] 'minor update'
  + **merged with theme** Add more platform specific props and helpers.
  
- [BaseLocalization] 'minor update'
  + **done** Custom/dynamic localization extractor for multi language API data.
  + **done** localizeDynamic - add custom parser param.
  + **done** localizePlural - add 'other' option.
  
- [BasePrefs] 'minor update'
  + Json - get/set is quit unstable right now. Add some safety checks..
  
- [BaseTheme] 'major update' - new class [ControlTheme]
  + **done** Add more Material and Cupertino constants and preferred values.
  + **done** Combine with [Device] to provide more runtime numbers based on physical device.
  
- [UnitId] 'new class'
  + **done**  Random id generator.
  + **done**  Sequence id generator on index and given string sequence (0 = a, 1 = b, 25 = z, 26 = aa).
  + **done**  Next id generator - based on timestamp.