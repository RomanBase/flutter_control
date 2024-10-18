part of '../../core.dart';

/// Standard initialization of object right after constructor.
/// In this approach constructor can be empty and [args] can contains all required dependencies. Kind of late property injection.
abstract class Initializable {
  /// Init is typically called right after constructor.
  /// [args] - these arguments are typically passed through factory.
  void init(Map args) {}
}

/// Base class within to implement Business logic.
/// This class is typically extended by custom BL Models to provide homogenous API through all code base.
/// Pass init [args] right after constructor to configure this model.
/// Comes with [DisposeHandler] so we can control how [dispose] will be handled.
/// When not restricted, [init] and [dispose] can be called multiple times during lifecycle of this model.
/// More specific use is implemented within [BaseControl] and [BaseModel].
class ControlModel with DisposeHandler implements Initializable {
  @override
  void init(Map args) {}

  /// Used to register interface/handler/notifier etc.
  /// Can be called multiple times with different objects!
  void mount(Object? object) {}

  @override
  void dispose() {
    super.dispose();

    //TODO: better log system to prevent unwanted spam
    printDebug('dispose: ${runtimeType.toString()}');
  }
}

/// Base class within to implement lightweight Business logic.
/// This class is typically extended by custom BL Models to provide homogenous API through all code base.
/// When not restricted, [init] can be called multiple times during lifecycle of this model.
/// Since this model [preferSoftDispose] by default, [dispose] must be called manually !
///
/// BaseModels are typically constructed and initialized manually within code, but also can be constructed through [ControlFactory] (Check [Control] service locator).
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

/// Base class within to implement robust Business logic.
/// This class is typically extended by custom BL Models to provide homogenous API through all code base.
/// [init] is 'replaced' with [onInit] that is called just once ([preventMultiInit] is set by default).
///
/// BaseControls are typically constructed by [ControlFactory] (Check [Control] service locator).
///
/// Check [BaseModel] for more lightweight implementation of [ControlModel].
/// Check [LazyControl], [ReferenceCounter] mixins to create even more powerful implementation.
class BaseControl extends ControlModel {
  /// Init check.
  bool _isInitialized = false;

  /// Return 'true' if init function was called before.
  bool get isInitialized => _isInitialized;

  /// Prevents multiple initialization and [onInit] will be called just once.
  bool preventMultiInit = true;

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

  /// Init is typically called right after constructor.
  /// Is called just once. To enable multi init set [preventMultiInit] to false.
  /// [args] - these arguments are typically passed through factory.
  void onInit(Map args) {}

  /// Reload model and data.
  Future<void> reload() async {}

  /// Invalidates Model and sets [isInitialized] to false.
  /// In some cases, from this point model can be re-initialized.
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
