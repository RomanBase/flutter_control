import 'package:flutter_control/core.dart';

class RoundInputDecoration extends InputDecoration {
  RoundInputDecoration({double radius: 12.0, Color color: Colors.white})
      : super(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: color.withOpacity(0.5))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: color.withOpacity(0.5))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: color)),
          disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(radius), borderSide: BorderSide(color: color.withOpacity(0.25))),
          hintStyle: TextStyle(color: color.withOpacity(0.5)),
          labelStyle: TextStyle(color: color.withOpacity(0.5)),
          errorStyle: TextStyle(fontSize: 0.0),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        );
}
