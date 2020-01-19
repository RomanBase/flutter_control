import 'package:flutter_control/core.dart';
import 'package:spends/fire/fire_control.dart';

class AccountControl extends BaseControl with RouteControlProvider, FireProvider {
  final loading = LoadingControl();

  void signOut() async {
    loading.progress();
    await fire.signOut();

    Control.root().notifyControlState(ControlArgs(LoadingStatus.progress));

    backToRoot();
  }
}
