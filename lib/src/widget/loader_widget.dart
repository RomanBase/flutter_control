import 'package:flutter_control/core.dart';

abstract class InitLoaderControl extends BaseControl {
  final loading = LoadingControl(LoadingStatus.progress);
  final Duration delay;

  StateNotifier state;

  InitLoaderControl({this.delay});

  factory InitLoaderControl.empty() => _InitLoaderControlEmpty();

  factory InitLoaderControl.of({
    Future<dynamic> Function(InitLoaderControl) load,
    Duration delay,
  }) =>
      _InitLoaderControlFunc(
        loadFunc: load,
        delay: delay,
      );

  @override
  void onInit(Map args) {
    super.onInit(args);

    state = args.getArg<StateNotifier>();

    executeLoader();
  }

  void executeLoader() async {
    loading.progress();

    DelayBlock block;

    if (delay != null) {
      block = DelayBlock(delay);
    }

    await Control.factory().onReady();

    final result = await load();

    if (block != null) {
      await block.finish();
    }

    notifyControl(LoadingStatus.done, result);
    loading.done();
  }

  Future<dynamic> load();

  void notifyControl(LoadingStatus status, [dynamic args]) {
    final result = ControlArgs(args);
    result[LoadingStatus] = status;

    state.notifyState(result);
  }

  @override
  void dispose() {
    super.dispose();

    loading.dispose();
  }
}

class _InitLoaderControlFunc extends InitLoaderControl {
  final Future<dynamic> Function(InitLoaderControl) loadFunc;

  _InitLoaderControlFunc({
    this.loadFunc,
    Duration delay,
  }) : super(delay: delay);

  @override
  Future<dynamic> load() async {
    dynamic result;

    if (loadFunc != null) {
      result = await loadFunc(this);
    }

    return result;
  }
}

class _InitLoaderControlEmpty extends InitLoaderControl {
  @override
  Future<void> load() => null;
}

class InitLoader<T extends InitLoaderControl> extends SingleControlWidget<T> {
  final WidgetBuilder builder;

  InitLoader({
    T control,
    @required this.builder,
  }) : super(args: control);

  factory InitLoader.of({
    Future<dynamic> Function(InitLoaderControl) load,
    Duration delay,
    @required WidgetBuilder builder,
  }) =>
      InitLoader(
        control: InitLoaderControl.of(
          load: load,
          delay: delay,
        ),
        builder: builder,
      );

  @override
  Widget build(BuildContext context) {
    return WidgetInitializer.of((context) => builder(context), control).getWidget(context, args: holder.args);
  }
}
