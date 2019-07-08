BaseApp initializes Control and Factory. It's little shortcut to start with Flutter Control.
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BaseApp(
      title: 'Flutter Control',
      theme: ThemeData(),
      entries: {
        'todo': MyController(),
      },
      root: (context) => MyWidget(),
    );
  }
}
```

Business logic layer.
```dart
class MyController extends BaseController {
  final count = FieldConrol<int>(0);

  void increment() => count.setValue(count.value++);

  void decrement() => count.setValue(count.value--);

  @override
  void dispose() {
    super.dispose();
    count.dispose();
  }
}
```

Presentation layer.
```dart
class MyWidget extends SingleControlWidget<MyController> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.add),
          onPressed: controller.increment,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: FieldBuilder<int>(
            controller: controller.count,
            builder: (context, value) => Text('$value'),
          ),
        ),
        IconButton(
          icon: Icon(Icons.remove),
          onPressed: controller.decrement,
        ),
      ],
    );
  }
}
```