part of '../../core.dart';

/// Standard initialization of object right after constructor.
abstract class Initializable {
  /// {@template init-object}
  /// Init is typically called right after constructor by framework.
  /// [args] - Arguments passed from parent or through Factory.
  /// {@endtemplate}
  void init(Map args) {}
}

/// {@template control-model}
/// Base class to use with [CoreWidget] - specifically [ControlWidget].
/// Logic part that handles Streams, loading, data, etc.
/// Init [args] helps to pass reference of other used Controls and objects.
///
/// Extend this class to create custom controls and models.
/// {@endtemplate}
class ControlModel with DisposeHandler implements Initializable {
  @override
  void init(Map args) {}

  /// Used to register interface/handler/notifier etc.
  /// Can be called multiple times with different objects!
  void mount(dynamic object) {}

  @override
  void dispose() {
    super.dispose();

    printDebug('dispose: ${runtimeType.toString()}');
  }
}

/// Extended version of [ControlModel]. Mainly used for complex Widgets as Pages or to separate/reuse logic.
///
/// @{macro control-model}
class BaseControl extends ControlModel {
  /// Init check.
  bool _isInitialized = false;

  /// Return 'true' if init function was called before.
  bool get isInitialized => _isInitialized;

  /// Prevents multiple initialization and [onInit] will be called just once.
  bool preventMultiInit = true;

  /// {@macro init-object}
  /// Set [preventMultiInit] to enable multi init / re-init
  @override
  @mustCallSuper
  void init(Map args) {
    if (isInitialized && preventMultiInit) {
      printDebug('controller is already initialized: ${this.runtimeType.toString()}');
      return;
    }

    _isInitialized = true;
    onInit(args);
  }

  /// Is typically called once and shortly after constructor.
  /// In most of times [Widget] or [State] isn't ready yet.
  /// [preventMultiInit] is enabled by default and prevents multiple calls of this function.
  /// [args] input arguments passed from parent or Factory.
  void onInit(Map args) {}

  /// Reload model and data.
  Future<void> reload() async {}

  /// Invalidates Control and sets [isInitialized] to false.
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

/// Lightweight version of [ControlModel]. Mainly used for simple Widgets as Items in dynamic List or to separate/reuse Logic, also to prevent dispose, because [BaseModel] overrides [preferSoftDispose].
/// [dispose] must be called manually !
///
/// @{macro control-model}
class BaseModel extends ControlModel {
  /// Default constructor.
  BaseModel() {
    preferSoftDispose = true;
  }
}
