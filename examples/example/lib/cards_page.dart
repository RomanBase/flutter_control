import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'settings_page.dart';

class CardsPage extends SingleControlWidget<CardsController> with RouteNavigator, ThemeProvider {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FieldBuilder<String>(
          control: control.countLabel,
          builder: (context, value) => Text('${localize('title')} - $value'),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => routeOf<SettingsPage>().openRoute(root: true),
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListBuilder<CardModel>(
              control: control.cards,
              builder: (context, items) {
                return ListView.builder(
                  itemCount: control.cards.length,
                  itemBuilder: (context, index) => CardWidget(control.cards[index]),
                );
              },
              noData: (context) => Center(
                child: Text(localize('empty_list')),
              ),
            ),
          ),
          Container(
            color: Colors.grey,
            padding: EdgeInsets.symmetric(horizontal: theme.padding, vertical: theme.paddingHalf),
            child: InputField(
              control: control.input,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: control.addCard,
        child: Icon(Icons.add),
      ),
    );
  }
}

class CardWidget extends BaseControlWidget with ThemeProvider {
  final CardModel item;

  CardWidget(this.item) : super(key: ObjectKey(item));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(offset: Offset(2.0, 2.0), blurRadius: 6.0, color: Colors.black45),
        ],
      ),
      child: FlatButton(
        padding: const EdgeInsets.all(16.0),
        onPressed: () => Control.get<CardsController>()?.openCard(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              item.title,
              style: font.title,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: FieldBuilder<String>(
                control: item.countLabel,
                builder: (context, text) => Text(text),
                noData: (context) => Text(localize('empty_card')),
              ),
            ),
            FieldBuilder<double>(
              control: item.progress,
              builder: (context, progress) => LinearProgressIndicator(value: progress),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends SingleControlWidget<DetailController> with RouteNavigator {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FieldBuilder<String>(
          control: control.title,
          builder: (context, title) => Text(title),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: control.deleteSelf,
          ),
        ],
      ),
      body: ListBuilder<CardItemModel>(
        control: control.items,
        builder: (context, items) {
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) => ItemWidget(items[index]),
          );
        },
        noData: (context) => Center(
          child: Text(localize('empty_list')),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: control.addItem,
        child: Icon(Icons.add),
      ),
    );
  }
}

class ItemWidget extends StatelessWidget {
  final CardItemModel item;

  ItemWidget(this.item) : super(key: ObjectKey(item));

  @override
  Widget build(BuildContext context) {
    return FlatButton(
      onPressed: item.toggle,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          FieldBuilder<bool>(
            control: item.done,
            builder: (context, done) => Checkbox(value: done, onChanged: item.changeState),
          ),
          Text(item.title),
        ],
      ),
    );
  }
}
