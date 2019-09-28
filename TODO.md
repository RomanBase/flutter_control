- Documentation

- Tests

- [BaseApp] 'semi-major update'
  Support for CupertinoApp.
  Add more params from MaterialApp.
  
- [AppControl] 'new purpose update'
  Is not currently used well and is mostly cleared.
  Try to find new purpose for this class..

- [ControlWidget] 'semi-major update'
  Better support for custom State
  Provide more State functions - directly or via mixins, some of them can be binded even to Controller.
  [StateHolder] - check build/hot reload, correct widget/state pairing, maybe more 'get' caching to save some performance
  [TickerControl] - better support for custom State
  [RouteControl] - more dialog options and custom Transitions

- [ArgHandler] x [Parse] 'minor update'
  Deprecate ArgHandler and upgrade Parse with functions from ArgHandler.
  getArg - accepts dynamic at input and decides what to do next - parse as list/map or is good or return default..
  getArgFromList - based on ArgHandler.list/ArgHandler.iterable
  getArgFromMap - based on ArgHandler.map

- [GlobalSubscription] x [ControlSubscription] x [FieldSubscription] 'major update'
  Compare these and maybe merge them or create interface/abstract class.

- [FieldControl] 'minor update'
  Provide save access to Stream or to major Stream functions.

- [ListControl] 'semi-major update'
  Implement Iterable or major functions from there..
  
- [StringControl] 'minor update'
  Add regex validation
  
- [InputField] 'minor update'
  Check/correct params or default values for latest Flutter version.
  
- [NavigatorController] and [NavigatorStackController] 'minor update'
  Provide controls to Controllers of child Widgets.
  
- [StableWidget] 'minor update'
  It's too stable :) hot reload not working now..
  
- [Device] 'minor update'
  Add more platform specific props and helpers.
  
- [BaseLocalization] 'minor update'
  Custom/dynamic localization extractor for multi language API data.
  
- [BasePrefs] 'fix'
  Json - get/set is quit unstable right now. Add some safety checks..
  
- [BaseTheme] 'major update'
  Add more Material and Cupertino constants and preferred values.
  Combine with [Device] to provide more runtime numbers based on physical device.
  
- [UnitId] 'new class'
  Random ids.
  Sequenced ids based on index (0 = a, 1 = b, 25 = z, 26 = aa).