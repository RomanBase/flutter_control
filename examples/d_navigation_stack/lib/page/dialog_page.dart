import 'package:d_navigation_stack/page/template_page.dart';
import 'package:flutter_control/core.dart';

class DialogControl extends ControlModel with RouteControlProvider {
  void openDialogFromControl() => routeOf<CustomDialog>().openDialog();
}

class DialogPage extends SingleControlWidget<DialogControl> with RouteControl {
  @override
  DialogControl initControl() => DialogControl();

  @override
  Widget build(BuildContext context) {
    return TemplatePage(
      title: 'dialogs',
      color: Colors.green,
      child: Column(
        children: <Widget>[
          RaisedButton(
            onPressed: () => control.openDialogFromControl(),
            child: Text('popup'),
          ),
          RaisedButton(
            onPressed: () => routeOf<CustomDialog>().openDialog(root: false),
            child: Text('popup inside'),
          ),
          RaisedButton(
            onPressed: () => openDialog((_) => CustomDialog(), type: 'custom_dialog'),
            child: Text('custom dialog'),
          ),
          RaisedButton(
            onPressed: () => openDialog((_) => CustomDialog(), type: 'sheet'),
            child: Text('sheet'),
          ),
        ],
      ),
    );
  }

  @override
  Future openDialog(WidgetBuilder builder, {bool root: true, dynamic type}) {
    switch (type) {
      case 'custom_dialog':
        return showGeneralDialog(
          context: context,
          transitionDuration: const Duration(milliseconds: 300),
          pageBuilder: (context, anim, anim2) {
            return Container(
              color: Colors.black45,
              child: SlideTransition(
                position: Tween<Offset>(begin: Offset(1.0, 0.0), end: Offset.zero).animate(anim),
                child: builder(context),
              ),
            );
          },
          barrierDismissible: false,
          useRootNavigator: root,
        );
      case 'sheet':
        return showModalBottomSheet(
          context: getContext(root: root), // If ControlScope.rootContext is not changed, then getContext(root: true) and userRootNavigator:true uses same Navigator.
          useRootNavigator: false,         // But some special app scenarios can require to change ControlScope.rootContext and prefer this way instead using useRootNavigator.
          builder: builder,
        );
    }

    return super.openDialog(builder, root: root, type: type);
  }
}

class CustomDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Container(
          height: 256.0,
          width: 256.0,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('dialog'),
              RaisedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('close'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
