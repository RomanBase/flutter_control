//TODO:
class BaseTheme {
  static const padding = 16.0;
  static const padding_half = 8.0;
  static const padding_quad = 4.0;
  static const padding_quarter = 12.0;
  static const padding_mid = 24.0;
  static const padding_extended = 32.0;
  static const padding_section = 64.0;
  static const padding_head = 96.0;

  static const icon_size = 24.0;
  static const icon_large_size = 32.0;
  static const icon_bounds = 48.0;

  static const icon_launcher = 144.0;
  static const thumb = 96.0;
  static const preview = 192.0;
  static const head = 320.0;

  static const button_width = 256.0;
  static const button_height = 56.0;
  static const button_radius = button_height * 0.5;
  static const button_height_small = 32.0;

  static const control_height = 42.0;
  static const input_height = 56.0;

  static const anim_duration = const Duration(milliseconds: 250);
  static const anim_duration_fast = const Duration(milliseconds: 150);
  static const anim_duration_slow = const Duration(milliseconds: 500);
  static const anim_duration_second = const Duration(milliseconds: 1000);

  /// Refers to assets/path
  static String asset(String path) => "assets/$path";

  /// Refers to assets/images/name.ext
  static String image(String name, [String ext = 'png']) => asset("images/$name.$ext");

  /// Refers to assets/icons/name.ext
  static String icon(String name, [String ext = 'png']) => asset("icons/$name.$ext");

  /// Refers to assets/data/name.ext
  static String data(String name, String ext) => asset("data/$name.$ext");
}
