part of flutter_control;

/// A control that manages an asynchronous loading process, typically during app initialization.
/// It transitions through loading states and, upon completion, can change the global [AppState].
abstract class InitLoaderControl extends BaseControl with ContextComponent {
  /// The loading state of the initialization process.
  final loading = LoadingControl(LoadingStatus.progress);

  /// An optional minimum duration for the loading process.
  final Duration? delay;

  InitLoaderControl({this.delay});

  /// Creates a functional [InitLoaderControl].
  ///
  /// [load] The asynchronous function to execute.
  /// [delay] An optional minimum duration for the loading process.
  factory InitLoaderControl.of({
    Future<dynamic> Function(InitLoaderControl)? load,
    Duration? delay,
  }) =>
      _InitLoaderControlFunc(
        loadFunc: load,
        delay: delay,
      );

  @override
  void onInit(Map args) {
    super.onInit(args);

    executeLoader();
  }

  /// Executes the loading process.
  void executeLoader() async {
    loading.progress();

    DelayBlock? block;

    if (delay != null) {
      block = DelayBlock(delay!);
    }

    await Control.factory.onReady();

    final result = await load();

    if (loading.hasError) {
      return;
    }

    if (block != null) {
      await block.finish();
    }

    final state = Parse.getArg<AppState>(result, defaultValue: AppState.main)!;

    notifyState(state);
  }

  /// The asynchronous loading operation. Must be implemented by subclasses.
  Future<dynamic> load();

  /// Notifies the [ControlRoot] to change the [AppState].
  void notifyState(AppState state) {
    context?.root.changeAppState(state);
  }

  @override
  void dispose() {
    super.dispose();

    loading.dispose();
  }
}

class _InitLoaderControlFunc extends InitLoaderControl {
  final Future<dynamic> Function(InitLoaderControl)? loadFunc;

  _InitLoaderControlFunc({
    this.loadFunc,
    Duration? delay,
  }) : super(delay: delay);

  @override
  Future<dynamic> load() async {
    dynamic result;

    if (loadFunc != null) {
      result = await loadFunc!(this);
    }

    return result;
  }
}

/// A widget that hosts an [InitLoaderControl] to manage an asynchronous
/// initialization process while displaying a UI.
class InitLoader<T extends InitLoaderControl> extends SingleControlWidget<T> {
  /// The widget to display during the loading process.
  final WidgetBuilder builder;

  /// Creates an [InitLoader] widget.
  ///
  /// [control] An instance of [InitLoaderControl] to manage the loading.
  /// [builder] The widget to display.
  InitLoader({
    T? control,
    required this.builder,
  }) : super(initArgs: ControlArgs.of(control).data);

  /// A factory for creating an [InitLoader] with a functional [InitLoaderControl].
  ///
  /// [load] The asynchronous function to execute.
  /// [delay] An optional minimum duration for the loading process.
  /// [builder] The widget to display.
  factory InitLoader.of({
    Future<dynamic> Function(InitLoaderControl)? load,
    Duration? delay,
    required WidgetBuilder builder,
  }) =>
      InitLoader(
        control: InitLoaderControl.of(
          load: load,
          delay: delay,
        ) as T?,
        builder: builder,
      );

  @override
  Widget build(CoreContext context, T control) {
    return builder(context);
  }
}
