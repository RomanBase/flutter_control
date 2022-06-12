import 'package:flutter_control/control.dart';

class RoundedButton extends StatelessWidget with ThemeProvider {
  final VoidCallback onPressed;
  final String title;
  final Widget icon;
  final Widget child;
  final Color color;
  final Color tint;
  final Color outline;
  final double width;
  final double height;
  final TextStyle style;
  final EdgeInsets padding;
  final bool round;

  RoundedButton({
    @required this.onPressed,
    this.title,
    this.icon,
    this.child,
    this.color,
    this.tint,
    this.outline,
    this.width,
    this.height: 56.0,
    this.style,
    this.padding,
    this.round: true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = round ? height * 0.5 : 0.0;
    final child = _buildChildWidget(context, false);

    Widget button;

    button = RaisedButton(
      onPressed: onPressed,
      elevation: 0.0,
      highlightElevation: 0.0,
      color: color ?? Theme.of(context).primaryColor,
      shape: _buttonShape(radius),
      child: child,
      splashColor: theme.data.splashColor,
      highlightColor: theme.data.highlightColor,
      padding: padding,
    );

    if (outline != null) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: outline),
        ),
        child: button,
      );
    } else {
      return Container(
        height: height,
        child: button,
      );
    }
  }

  Widget _buildChildWidget(BuildContext context, bool expand) {
    if (child != null) {
      return child;
    }

    final textStyle = style ?? theme.font.button;
    final text = title != null
        ? Text(title,
            style: tint != null ? textStyle.copyWith(color: tint) : textStyle)
        : null;

    if (icon != null) {
      final list = List<Widget>();
      list.add(icon);

      if (text != null) {
        list.add(SizedBox(width: theme.padding));
        list.add(text);
      }

      return Padding(
        padding: EdgeInsets.symmetric(horizontal: theme.paddingHalf),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: list,
        ),
      );
    }

    if (expand) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[text],
      );
    }

    return text;
  }

  RoundedRectangleBorder _buttonShape(double radius) {
    return RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(radius)));
  }
}

class FadeButton extends StatefulWidget {
  final Widget child;
  final double height;
  final double width;
  final EdgeInsets padding;
  final double opacity;
  final Duration duration;
  final VoidCallback onPressed;

  const FadeButton({
    Key key,
    @required this.onPressed,
    this.child,
    this.height: 56.0,
    this.width,
    this.padding,
    this.opacity: 0.25,
    this.duration: const Duration(milliseconds: 150),
  }) : super(key: key);

  @override
  _FadeButtonState createState() => _FadeButtonState();
}

class _FadeButtonState extends State<FadeButton> with ThemeProvider {
  double _opacity = 1.0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      onTapDown: (args) => _setOpacity(widget.opacity),
      onTapUp: (args) => _setOpacity(1.0),
      onTapCancel: () => _setOpacity(1.0),
      child: Container(
        width: widget.width,
        height: widget.height,
        color: Colors.transparent,
        padding: widget.padding ??
            EdgeInsets.symmetric(horizontal: theme.paddingHalf),
        child: AnimatedOpacity(
          opacity: _opacity,
          duration: widget.duration,
          child: Center(
            child: widget.child,
          ),
        ),
      ),
    );
  }

  void _setOpacity(double opacity) => setState(() {
        _opacity = opacity;
      });
}
