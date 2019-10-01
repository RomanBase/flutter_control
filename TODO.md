- Documentation
  + All, mainly Factory, BaseApp, BaseController, ControlWidget, FieldControl

- Tests
  + Factory.
  + BaseController.
  + FieldControl.
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

- [BaseApp] 'semi-major update'
  + Support for CupertinoApp. Currently everything is based on 'package:flutter/material.dart' from [Core] export.
  + Add more params from MaterialApp.
  
- [AppControl] 'new purpose update'
  + Is not currently used well and is mostly cleared.
  + Try to find new purpose for this class..
  
- [BaseFactory] 'semi-major update'
  + **done** Merge or clean up some shady functions.
  + **done** 'add' vs. 'addItem' functions - 'object' to store is required and 'key' can be empty.
  + **done** 'get' vs. 'getWith' - can be merged.
  + **done** 'find' - make it more generic and use Parse/ArgHandler to help find object from input collection.

- [ControlWidget] 'semi-major update'
  + Better support for custom State
  + Provide more State functions - directly or via mixins, some of them can be binded even to Controller.
  + [StateHolder] - check build/hot reload, correct widget/state pairing, maybe more 'get' caching to holder to save some performance
  + [TickerControl] - better support for custom State
  + [RouteControl] - more dialog options and custom Transitions

- [ArgHandler] x [Parse] 'minor update'
  + **done** Deprecate ArgHandler and upgrade Parse with functions from ArgHandler.
  + **done** 'getArg' - accepts dynamic at input and decides what to do next - use getArgFrom List/Map or cast, use other parse method or return default..
  + **done** 'getArgFromList' - based on ArgHandler.list/ArgHandler.iterable
  + **done** 'getArgFromMap' - based on ArgHandler.map
  + **done** 'getArgFromString' - parse input to json and then return object.

- [GlobalSubscription] x [ControlSubscription] x [FieldSubscription] 'major update'
  + Compare these and maybe merge them or create interface/abstract class.

- [FieldControl] 'minor update'
  + Provide save access to Stream or to major Stream functions.

- [ListControl] 'semi-major update'
  + Implement whole Iterable or just major functions from there..
  
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
  + Add more platform specific props and helpers.
  
- [BaseLocalization] 'minor update'
  + **done** Custom/dynamic localization extractor for multi language API data.
  + **done** localizeDynamic - add custom parser param.
  + **done** localizePlural - add 'other' option.
  
- [BasePrefs] 'minor update'
  + Json - get/set is quit unstable right now. Add some safety checks..
  
- [BaseTheme] 'major update'
  + Add more Material and Cupertino constants and preferred values.
  + Combine with [Device] to provide more runtime numbers based on physical device.
  
- [UnitId] 'new class'
  + Random id generator.
  + Sequenced id based generator on index and given string sequence (0 = a, 1 = b, 25 = z, 26 = aa).