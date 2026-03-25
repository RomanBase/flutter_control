---
description: AI Agent Implementation Guide for flutter_control
scope: Global workspace
---

# `flutter_control` - AI Agent Guidelines

## Context
This document defines the architectural boundaries, invariant rules, and golden patterns for the `flutter_control` Flutter framework. AI agents MUST reference these patterns when generating, refactoring, or analyzing code in this repository.

## Core Mental Models

- **`ControlFactory`**: The global Service Locator and Dependency Injection (DI) container.
- **`CoreContext`**: An enhanced `BuildContext` provided by `CoreWidget` / `BaseControlWidget`. It provides localized DI, hooks, and routing extensions.
- **`ControlModel` & `BaseControl`**: The primary base classes for business logic controllers (ViewModels). `BaseControl` provides expanded lifecycle checks (`isInitialized`, `isDisposed`).
- **Mixins**: Extensions that enhance `ControlModel`s (e.g., `ContextComponent` grants access to the host widget's `CoreContext`, `TickerComponent` grants a `TickerProvider`).
- **`ControlObservable`**: The base reactive primitive. Subtypes include `ActionControl` (simple values/events) and `FieldControl` (streams with validation).
- **Hooks (Lazy Initialization)**: Objects tied to a widget's lifecycle. Initialized via `context.use<T>()` and automatically disposed.

---

## Constraints & Invariants (Do's and Don'ts)

### 1. State Management & Observables
- **DO** use `ActionControl` or `FieldControl` combined with `ControlBuilder` for targeted, granular UI rebuilds.
- **DON'T** use standard `setState()` unless absolutely necessary for simple, isolated UI toggles. Prefer reactive observables.
- **DO** use `context.registerStateNotifier(observable)` inside a widget's `onInit` if you want the *entire widget* to rebuild when an observable changes (useful for global state changes).
- **DO** use `context.notifyState()` to manually force a rebuild of a `CoreWidget` from the inside.

### 2. Dependency Injection & Hooks
- **DO** use `context.use<T>(value: () => T())` to instantiate local dependencies or controllers that should automatically dispose when the widget unmounts.
- **DON'T** create manual `StatefulWidget` classes just to manage an `AnimationController` or `ScrollController`.
- **DO** use the built-in hooks: `context.animation()`, `context.scroll()`, and `context.ticker`.
- **DO** use `SingleControlWidget<T>` when your widget is tightly coupled to a single `ControlModel` of type `T`.

### 3. Lifecycle & Initialization
- **DO** perform widget-level setup in `void onInit(Map args, CoreContext context)` for `SingleControlWidget` or `ControlWidget`.
- **DO** perform logic-level setup in `void onInit(Map args)` for `ControlModel` / `BaseControl`.
- **DON'T** perform heavy initialization or register dependencies inside the `build()` method.

### 4. Navigation & Routing
- **DO** use `context.routeOf<T>()?.openRoute()` or `context.routeOf(identifier: 'id')?.openRoute()` for navigation.
- **DON'T** use raw `Navigator.of(context).push()` if the route is part of the `RouteStore`.
- **DO** use the `InitProvider` mixin on your widget class to automatically parse and load navigation arguments into `context.args`.

---

## Golden Examples (Implementation Patterns)

### Pattern 1: `SingleControlWidget` with `BaseControl` and Observables
This demonstrates the complete architecture: A logic controller (`BaseControl` with mixins), reactive state (`ActionControl`), widget initialization (`onInit`), and UI binding (`ControlBuilder` and `registerStateNotifier`).

```dart
// 1. Define the Business Logic Controller
class UserProfileControl extends BaseControl with ContextComponent {
  final userName = ActionControl.broadcast<String>('Guest');
  final globalThemeToggle = ActionControl.broadcast<bool>(false);

  @override
  void onInit(Map args) {
    super.onInit(args);
    // Logic-level initialization. args are passed down from the widget.
    userName.value = args.getArg<String>(key: 'initialName', defaultValue: 'Guest');
  }

  void updateName(String newName) {
    userName.value = newName;
  }
}

// 2. Define the UI Widget
// SingleControlWidget automatically resolves and provides UserProfileControl to build().
class UserProfilePage extends SingleControlWidget<UserProfileControl> {
  @override
  void onInit(Map args, CoreContext context) {
    super.onInit(args, context);
    
    // Widget-level initialization.
    // Rebuild the ENTIRE widget whenever globalThemeToggle changes.
    context.registerStateNotifier(control.globalThemeToggle);
  }

  @override
  Widget build(BuildContext context, UserProfileControl control) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          // ControlBuilder enables GRANULAR rebuilds. Only this text rebuilds when userName changes.
          ControlBuilder<String>(
            control: control.userName,
            builder: (context, name) => Text('Hello, $name'),
          ),
          ElevatedButton(
            onPressed: () => control.updateName('Admin'),
            child: const Text('Set Admin'),
          ),
        ],
      ),
    );
  }
}
```

### Pattern 2: Receiving Route Arguments
Always use `InitProvider` to extract arguments.

```dart
// RIGHT
class UserProfilePage extends BaseControlWidget with InitProvider {
  @override
  Widget build(CoreContext context) {
    // context.args is populated automatically by InitProvider
    final userId = context.args.get<String>(key: 'userId');
    
    return Text('User ID: $userId');
  }
}

// WRONG
// Trying to extract from ModalRoute manually inside build()
```

### Pattern 3: Using Built-in Hooks
Avoid `StatefulWidget` boilerplate for standard Flutter controllers.

```dart
// RIGHT
class AnimatedPage extends BaseControlWidget {
  @override
  Widget build(CoreContext context) {
    // Automatically creates, manages vsync (ticker), and disposes the controller.
    // stateNotifier: true rebuilds the widget on every animation tick.
    final anim = context.animation(
      duration: const Duration(seconds: 1),
      stateNotifier: true, 
    );

    return Opacity(
      opacity: anim.value,
      child: const Text('Fading In'),
    );
  }
}
```

### Pattern 4: Local Overlay Hook
Managing floating UI elements associated with a widget.

```dart
// RIGHT
void showTooltip(CoreContext context) {
  context.showOverlay(
    key: 'info_tooltip',
    builder: (parentRect) => Positioned(
      top: parentRect.bottom,
      left: parentRect.left,
      child: const Text('Tooltip info'),
    ),
  );
}

void hideTooltip(CoreContext context) {
  context.hideOverlay('info_tooltip');
}
```

### Pattern 5: Custom Dependency Hook
Binding a generic service to a widget's lifecycle.

```dart
// RIGHT
class ServicePage extends BaseControlWidget {
  @override
  Widget build(CoreContext context) {
    // LocalService will be created once and disposed when ServicePage unmounts.
    final service = context.use<LocalService>(
      value: () => LocalService(),
      dispose: (obj) => obj.close(),
    );

    return Text(service.data);
  }
}
```