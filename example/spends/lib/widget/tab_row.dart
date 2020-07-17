import 'package:flutter_control/core.dart';

class TabRow extends StatelessWidget {
  final String title;
  final String value;
  final FieldControl<String> control;
  final TextStyle style;

  const TabRow({
    Key key,
    @required this.title,
    this.value,
    this.control,
    this.style,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final style = this.style ?? Theme.of(context).textTheme.bodyText1;

    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            title,
            style: style,
          ),
        ),
        control != null
            ? FieldBuilder<String>(
                control: control,
                builder: (context, value) => Text(
                  value,
                  style: style,
                ),
              )
            : Text(
                value ?? '-',
                style: style,
              ),
      ],
    );
  }
}
