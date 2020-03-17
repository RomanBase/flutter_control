import 'package:flutter_control/core.dart';

class TemplatePage extends StatelessWidget {
  final String title;
  final Color color;
  final Widget child;

  const TemplatePage({
    Key key,
    this.title: 'template',
    this.color: Colors.white,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: color,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: Theme.of(context).textTheme.title,
            ),
            SizedBox(
              height: 32.0,
            ),
            child ?? Container(),
          ],
        ),
      ),
    );
  }
}
