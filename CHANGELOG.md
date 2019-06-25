## [0.1.1] - Struct
## [0.1.0] - StackNavigator for bottom menu, tabs, multi pages, etc.
Minor changes to Control workflow.

* Core implementation of Control skeleton. Controller and Stream workflow to separate app logic from Widgets.

AppFactory instance for object initialization and store. Also works as global multi-stream.

AppBase as top layer Widget - setups all core Controls.
AppControl as top layer InheritedWidget with access to all core Control objects.

AppLocalization - basic .json based localization.
AppPrefs - just wrapping for SharedPreferences plugin.
BaseTheme - some basic sizes etc.

---

ControlWidget is base StatefulWidget of Control workflow. Some functionality is pulled from ControlState to prevent overuse of States.
 - ticker variants: ControlTickerWidget, ControlSingleTickerWidget.

RouteControl is mixin for ControlWidget to enable Navigation via Controllers.
RouteHandler wraps Navigator routing and Widgets initialization.
NavigationStack wraps Navigator and adds some functionality for Controllers.
InputField wraps TextField and adds some functionality for Controllers.
FieldBuilder wraps StreamBuilder and adds some functionality for Controllers.
 - basic variants: FieldBoolBuilder, FieldListBuilder, etc.

---

BaseController is base controller used with ControlWidget.
StateController can notify ControlWidget about State changes.
RouteController is mixin to enable Navigation from Controller.
FieldController wraps Stream for easier use and adds some functionality.
 - basic variants: BoolController, ListController, ObjectController, etc.

---

Some utils, helpers etc.
