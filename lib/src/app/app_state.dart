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
  MapEntry<AppState, CrossTransition> get transitionEntry =>
      MapEntry(key, transition!);

  /// Builds case:builder map for given states.
  static Map<AppState, WidgetBuilder> fillBuilders(
          List<AppStateBuilder> items) =>
      items
          .asMap()
          .map<AppState, WidgetBuilder>((key, value) => value.builderEntry);

  /// Builds case:transition map for given states.
  static Map<AppState, CrossTransition> fillTransitions(
          List<AppStateBuilder> items) =>
      items
          .where((item) => item.transition != null)
          .toList()
          .asMap()
          .map<AppState, CrossTransition>(
              (key, value) => value.transitionEntry);
}

/// Representation of App State handled by [ControlRoot].
/// [AppState.init] is considered as initial State - used during App loading.
/// [AppState.main] is considered as default App State.
/// Other predefined States (as [AppState.onboarding]) can be used to separate main App States and their flow.
/// It's possible to create custom States by extending [AppState].
///
/// Change State via [ControlScope.root].
class AppState {
  /// Initial state of the application. Typically used during loading or initialization.
  static const init = AppState();

  /// State representing the authentication flow.
  static const auth = _AppStateAuth();

  /// State representing the onboarding flow.
  static const onboarding = _AppStateOnboarding();

  /// The default main state of the application.
  static const main = _AppStateMain();

  /// State for when the application is running in the background.
  static const background = _AppStateBackground();

  /// Default constructor for [AppState].
  const AppState();

  /// Creates an [AppStateBuilder] for this state.
  /// [builder] - Function to build the widget for this state.
  /// [transition] - Animation to use when transitioning to this state.
  AppStateBuilder build(WidgetBuilder builder, {CrossTransition? transition}) =>
      AppStateBuilder(
        this,
        builder,
        transition,
      );

  /// Returns the type of this state, used as a key in maps.
  Type get key => runtimeType;

  @override
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
