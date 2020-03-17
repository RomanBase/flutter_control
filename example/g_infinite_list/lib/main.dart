import 'package:flutter_control/core.dart';

import 'list_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ControlRoot(
      root: (context, args) => ListPage(),
      app: (context, key, home) => MaterialApp(
        key: key,
        home: home,
        title: 'Infinite List - Flutter Control',
      ),
    );
  }
}


