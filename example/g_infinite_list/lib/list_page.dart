import 'package:flutter_control/core.dart';

import 'items_control.dart';

class _UIControl extends ControlModel {
  final scroll = ScrollController();

  ItemsControl _control;
  double _offset = 0.0;

  @override
  void init(Map args) {
    super.init(args);

    scroll.addListener(_onScroll);
  }

  void _onScroll() {
    if (scroll.position.pixels >= scroll.position.maxScrollExtent - _offset && _control.loading.isDone) {
      _control.loadMore();
    }
  }
}

class ListPage extends ControlWidget {
  final ui = _UIControl();
  final control = ItemsControl();

  @override
  List<ControlModel> initControls() {
    ui._control = control;

    return [ui, control];
  }

  @override
  void onInit(Map args) {
    super.onInit(args);

    ui._offset = Device.of(context).dp(256.0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListBuilder(
        control: control.list,
        noData: (context) => LoadingBuilder(
          control: control.loading,
          progress: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                CircularProgressIndicator(),
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text('loading initial data'),
                ),
              ],
            ),
          ),
        ),
        builder: (context, list) {
          return ListView.builder(
            controller: ui.scroll,
            itemCount: list.length + 1,
            itemBuilder: (context, index) {
              if (index == list.length) {
                return Container(
                  height: 96.0,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              return ListItem(
                model: list[index],
              );
            },
          );
        },
      ),
    );
  }
}

class ListItem extends StatelessWidget {
  final ItemModel model;

  const ListItem({Key key, this.model}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      height: 128.0,
      color: Colors.grey,
      child: Center(
        child: Text(
          model.title,
          style: Theme.of(context).textTheme.headline3,
        ),
      ),
    );
  }
}
