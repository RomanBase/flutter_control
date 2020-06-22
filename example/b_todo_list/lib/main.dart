import 'package:flutter_control/core.dart';

import 'list_control.dart';
import 'list_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      entries: {
        TodoListControl: TodoListControl(),
      },
      initializers: {
        ItemDialogControl: (_) => ItemDialogControl(),
      },
      states: <AppStateSetup>[
        AppState.main.build((context) => TodoListPage()),
      ],
      app: (setup, home) {
        return MaterialApp(
          key: setup.key,
          home: home,
          title: 'Todo List - Flutter Control',
        );
      },
    );
  }
}
