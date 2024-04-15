part of flutter_control;

/// Setup of [AppState].
/// Holds case [key], [builder] and [transition]
class AppStateBuilder {
  /// Case key of [AppState].
  final AppState key;

  /// Case builder for this state.
  final WidgetBuilder builder;

  /// Case transaction to this state.
  final CrossTransition? transition;

  /// Setup of [AppState].
  /// [key] - Case representing [AppState].
  /// [builder] - Builder for given case.
  /// [transition] - Animation from previous Widget to given case.
  const AppStateBuilder(
    this.key,
    this.builder,
    this.transition,
  );

  /// Returns case:builder entry.
  MapEntry<AppState, WidgetBuilder> get builderEntry => MapEntry(key, builder);

  /// Returns case:transition entry.
  MapEntry<AppState, CrossTransition> get transitionEntry => MapEntry(key, transition!);

  /// Builds case:builder map for given states.
  static Map<AppState, WidgetBuilder> fillBuilders(List<AppStateBuilder> items) => items.asMap().map<AppState, WidgetBuilder>((key, value) => value.builderEntry);

  /// Builds case:transition map for given states.
  static Map<AppState, CrossTransition> fillTransitions(List<AppStateBuilder> items) => items.where((item) => item.transition != null).toList().asMap().map<AppState, CrossTransition>((key, value) => value.transitionEntry);
}

/// Representation of App State handled by [ControlRoot].
/// [AppState.init] is considered as initial State - used during App loading.
/// [AppState.main] is considered as default App State.
/// Other predefined States (as [AppState.onboarding]) can be used to separate main App States and their flow.
/// It's possible to create custom States by extending [AppState].
///
/// Change State via [ControlRootScope] -> [Control.root].
class AppState {
  static const init = const AppState();

  static const auth = const _AppStateAuth();

  static const onboarding = const _AppStateOnboarding();

  static const main = const _AppStateMain();

  static const background = const _AppStateBackground();

  const AppState();

  AppStateBuilder build(WidgetBuilder builder, {CrossTransition? transition}) => AppStateBuilder(
        this,
        builder,
        transition,
      );

  Type get key => this.runtimeType;

  operator ==(Object other) => other is AppState && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class _AppStateAuth extends AppState {
  const _AppStateAuth();
}

class _AppStateOnboarding extends AppState {
  const _AppStateOnboarding();
}

class _AppStateBackground extends AppState {
  const _AppStateBackground();
}

class _AppStateMain extends AppState {
  const _AppStateMain();
}

class ControlRoot extends ControlWidget {
  final ThemeConfig? theme;
  final AppState? initState;
  final List<AppStateBuilder> states;
  final List<dynamic> stateNotifiers;
  final List<Type> builders;
  final Widget Function(RootContext context, Widget home) builder;
  final VoidCallback? onSetupChanged;

  const ControlRoot({
    this.theme,
    this.initState,
    this.states = const [],
    this.stateNotifiers = const [],
    this.builders = const [],
    required this.builder,
    this.onSetupChanged,
  });

  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);

    if (theme != null) {
      context<ThemeConfig>(value: () => theme!, stateNotifier: true);
    }

    context.value<AppState>(value: initState ?? AppState.init, stateNotifier: true);

    stateNotifiers.forEach((element) => context.registerStateNotifier(element));
    builders.forEach((element) {
      final object = Control.get(key: element);
      if (object != null) {
        (context as RootContext).registerBuilder(object);
      }
    });
  }

  @override
  CoreContext createElement() => RootContext(this, initArgs);

  @override
  Widget build(CoreContext context) {
    printAction(() => 'BUILD CONTROL ROOT: ${Parse.name(context.value<AppState>().value)} | ${ThemeConfig.preferredTheme} | ${Control.get<Localino>()?.locale}');

    return builder(
      context as RootContext,
      ControlBuilder<AppState>(
        control: context.value<AppState>(),
        valueConverter: (_) => context.value<AppState>().value!,
        builder: (context, value) => CaseWidget<AppState>(
          activeCase: value,
          builders: AppStateBuilder.fillBuilders(states),
          transitions: AppStateBuilder.fillTransitions(states),
        ),
      ),
    );
  }
}

class RootContext extends CoreContext {
  static RootContext? of(BuildContext context) => context.findRootAncestorStateOfType<CoreState>()?.element as RootContext;

  AppState get appState => value<AppState>().value ?? AppState.init;

  RootContext(
    super.widget,
    super.initArgs,
  );

  void registerBuilder(dynamic object) {
    register(ControlObservable.of(object).subscribe((value) {
      _rebuildElement(this);
      (widget as ControlRoot).onSetupChanged?.call();
    }));
  }

  void _rebuildElement(Element el) {
    el.markNeedsBuild();
    el.visitChildren(_rebuildElement);
  }

  void changeAppState(AppState state) => value<AppState>().value = state;

  void changeTheme(dynamic key, [bool preferred = true]) => get<ThemeConfig>()?.changeTheme(key, preferred);

  @override
  void notifyState() {
    super.notifyState();

    (widget as ControlRoot).onSetupChanged?.call();
  }
}

extension CoreContextExt on BuildContext {
  RootContext get root => RootContext.of(this)!;
}
