import 'package:flutter_control/core.dart';

abstract class InitLoaderControl extends BaseControl {
  final loading = LoadingControl(LoadingStatus.progress);
  final Duration? delay;

  InitLoaderControl({this.delay});

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

    final state = Parse.getArg<AppState>(result, defaultValue: AppState.main);
    notifyControl(state, result);
  }

  Future<dynamic> load();

  void notifyControl(AppState? state, [dynamic args]) {
    Control.scope.setAppState(state, args: args);
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

class InitLoader<T extends InitLoaderControl> extends SingleControlWidget<T> {
  final WidgetBuilder builder;

  InitLoader({
    T? control,
    required this.builder,
  }) : super(args: control);

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
  Widget? build(BuildContext context) {
    return WidgetInitializer.of((context) => builder(context), control)
        .getWidget(context, args: holder.args);
  }
}
