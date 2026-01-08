part of '../../core.dart';

/// An interface for objects that can be initialized with arguments after construction.
///
/// This allows for a form of dependency injection or late initialization where
/// dependencies are provided via the [init] method instead of the constructor.
abstract class Initializable {
  /// Initializes the object with a map of arguments.
  ///
  /// This method is typically called by a factory (like `ControlFactory`) immediately
  /// after the object is instantiated.
  ///
  /// - [args]: A map of arguments, often used to pass dependencies or configuration.
  void init(Map args) {}
}

/// The foundational class for business logic models in the control framework.
///
/// It establishes a common lifecycle with [init], [mount], and [dispose] methods.
/// It also includes [DisposeHandler] to manage how `dispose` is handled.
///
/// By default, [init] and [dispose] can be called multiple times. For more
/// specific behaviors, see [BaseModel] and [BaseControl].
class ControlModel with DisposeHandler implements Initializable {
  @override
  void init(Map args) {}

  /// A lifecycle method for attaching external objects, such as notifiers or handlers.
  ///
  /// This can be called multiple times with different objects to establish connections
  /// between the model and other parts of the application.
  void mount(Object? object) {}

  @override
  void dispose() {
    super.dispose();

    //TODO: better log system to prevent unwanted spam
    printDebug('dispose: ${runtimeType.toString()}');
  }
}

/// A lightweight business logic model that prefers soft disposal by default.
///
/// `BaseModel` is intended for objects that are often created and destroyed, but
/// where a full `dispose` might be premature (e.g., items in a list).
///
/// By default, `preferSoftDispose` is `true`, meaning `requestDispose` will call
/// `softDispose` instead of the full `dispose`. A manual call to `dispose` is
/// still required for final cleanup.
///
/// It's suitable for manual instantiation or retrieval from the [ControlFactory].
///
/// Check [BaseControl] for more robust implementation of [ControlModel].
/// Check [ObservableComponent], [NotifierComponent] mixins to create observable version of model.
class BaseModel extends ControlModel {
  /// Prefer soft dispose by default.
  bool _preferSoftDispose = true;

  @override
  bool get preferSoftDispose => _preferSoftDispose;

  @override
  set preferSoftDispose(bool value) {
    _preferSoftDispose = value;
  }
}

/// A robust business logic model that ensures `onInit` is called only once.
///
/// `BaseControl` is designed for more complex components like page controllers or
/// services that should have a single, reliable initialization phase.
///
/// It's typically constructed and managed by the [ControlFactory] and often used
/// with mixins like [LazyControl] and [ReferenceCounter] for automatic lifecycle management.
///
/// Check [BaseModel] for more lightweight implementation of [ControlModel].
class BaseControl extends ControlModel {
  /// Init check.
  bool _isInitialized = false;

  /// Return 'true' if init function was called before.
  bool get isInitialized => _isInitialized;

  /// A flag to ensure `onInit` is called only once. Set to `false` to allow multiple initializations.
  bool preventMultiInit = true;

  /// Overrides the default `init` to guard against multiple initializations.
  ///
  /// It calls [onInit] the first time it's executed and does nothing on subsequent calls
  /// if [preventMultiInit] is `true`.
  @override
  @mustCallSuper
  void init(Map args) {
    if (isInitialized && preventMultiInit) {
      printDebug(
          'controller is already initialized: ${runtimeType.toString()}');
      return;
    }

    _isInitialized = true;
    onInit(args);
  }

  /// The main initialization method, called once after the constructor.
  ///
  /// Use this method for your primary setup logic.
  ///
  /// - [args]: Arguments passed from the factory.
  void onInit(Map args) {}

  /// A method to refresh or reload the model's data.
  Future<void> reload() async {}

  /// Resets the model's initialization state, allowing [onInit] to be called again.
  void invalidate() {
    _isInitialized = false;
  }

  @override
  @mustCallSuper
  void dispose() {
    super.dispose();
    _isInitialized = false;
  }
}
