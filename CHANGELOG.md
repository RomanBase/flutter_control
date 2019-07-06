## [0.8.95] - BaseApp and Control initialization
## [0.8.5] - Alpha version
- [BaseApp] Wraps MaterialApp and initializes Control and Factory. It's just shortcut to start with Flutter Control.
- [AppControl] Is [InheritedWidget] around whole App. Holds root Context and global Key.
- [ControlFactory] Mainly initializes and stores Controllers, Models and other Logic classes. Also works as global Stream to provide communication and synchronization between separated parts of App.

- [ActionControl] Single or Broadcast Observable. Usable with [ControlBuilder] to dynamically build Widgets.
- [FieldControl] Stream wrapper to use with [FieldStreamBuilder] or [FieldBuilder] to dynamically build Widgets.

- [BaseController] Stores all Business Logic and initializes self during Widget construction. Have native access to Factory and Control.
- [StateController] Adds functionality to notify State of [ControlWidget].
- [RouteController] Mixin for [BaseController] to enable Control Route Navigator. ([ControlWidget] must implement [RouteControl])
- [BaseModel] Lightweight version of Controller. Mainly used for Items in dynamic List or to separate/reuse Logic.  

- [ControlWidget] Base Widget to work with Controllers. Have native access to Factory and Control. 
- [BaseControlWidget] Widget with no init Controllers, but still have access to Factory etc. so Controllers can be get from there.
- [SingleControlWidget] Widget with just one generic Controller.
- [RouteControl] Mixin for [ControlWidget] to enable Control Route Navigation. ([BaseController] must implement [RouteController])
- [TickerControl] Mixin for [ControlWidget] to provide TickerProvider for AnimationControllers.
