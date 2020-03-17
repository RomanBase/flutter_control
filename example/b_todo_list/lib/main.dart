import 'package:flutter_control/core.dart';

import 'list_control.dart';
import 'list_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      disableLoader: true,
      entries: {
        TodoListControl: TodoListControl(),
      },
      initializers: {
        ItemDialogControl: (_) => ItemDialogControl(),
      },
      root: (context, args) => TodoListPage(),
      app: (context, key, home) {
        return MaterialApp(
          key: key,
          home: home,
          title: 'Todo List - Flutter Control',
        );
      },
    );
  }
}
