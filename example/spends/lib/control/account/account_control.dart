import 'package:flutter_control/control.dart';
import 'package:spends/fire/fire_control.dart';

class AccountControl extends BaseControl
    with RouteNavigatorProvider, FireProvider {
  final loading = LoadingControl();

  void signOut() async {
    loading.progress();
    await fire.signOut();

    ControlScope.root.setInitState();

    navigator.backToRoot();
  }
}
