import 'dart:io';

import 'package:flutter_control/core.dart';

//TODO: as extension or has this any purpose or whatever right now ???

T onPlatform<T>({
  Initializer<T> android,
  Initializer<T> ios,
  Initializer<T> mobile,
  Initializer<T> mac,
  Initializer<T> win,
  Initializer<T> desktop,
  Initializer<T> all,
  dynamic args,
}) {
  switch (Platform.operatingSystem) {
    case 'android':
      return _platformFuncSwitch(android, mobile, all, args);
    case 'ios':
      return _platformFuncSwitch(ios, mobile, all, args);
    case 'macos':
      return _platformFuncSwitch(mac, desktop, all, args);
    case 'windows':
      return _platformFuncSwitch(win, desktop, all, args);
    case 'linux':
      return _platformFuncSwitch(null, desktop, all, args);
    case 'fuchsia':
      return _platformFuncSwitch(null, desktop, all, args);
    default:
      return all == null ? null : all(args);
  }
}

T _platformFuncSwitch<T>(Initializer<T> platform, Initializer<T> alter, Initializer<T> all, dynamic args) {
  if (platform != null) {
    return platform(args);
  }

  if (alter != null) {
    return alter(args);
  }

  if (all != null) {
    return all(args);
  }

  return null;
}
