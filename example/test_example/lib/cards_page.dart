import 'package:flutter_control/core.dart';

import 'cards_controller.dart';
import 'settings_page.dart';

class CardsPage extends SingleControlWidget<CardsController>
    with RouteControl, ThemeProvider {
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
                  itemBuilder: (context, index) =>
                      CardWidget(control.cards[index]),
                );
              },
              noData: (context) => Center(
                child: Text(localize('empty_list')),
              ),
            ),
          ),
          ControlBuilderGroup(
            controls: [control.input, control.countLabel, control.cards],
            builder: (context, values) => Text('$values'),
          ),
          Container(
            color: Colors.grey,
            padding: EdgeInsets.symmetric(
                horizontal: theme.padding, vertical: theme.paddingHalf),
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

class CardWidget extends ControllableWidget<CardModel>
    with ThemeProvider, LocalizationProvider {
  final CardModel item;

  CardWidget(this.item) : super(item, key: ObjectKey(item));

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              offset: Offset(2.0, 2.0), blurRadius: 6.0, color: Colors.black45),
        ],
      ),
      child: FlatButton(
        padding: const EdgeInsets.all(16.0),
        onPressed: () => Control.get<CardsController>()?.openCard(item),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Text(
                  item.title,
                  style: font.headline6,
                ),
                Spacer(),
                CaseWidget(
                  activeCase: item.items.length,
                  builders: {
                    0: (_) => Text('A'),
                    1: (_) => Text('B'),
                    2: (_) => Text('C'),
                  },
                  placeholder: (_) => Text('#'),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(item.countLabel.isEmpty
                  ? localize('empty_card')
                  : item.countLabel.value),
            ),
            FieldBuilder<double>(
              control: item.progress,
              builder: (context, progress) =>
                  LinearProgressIndicator(value: progress),
            ),
          ],
        ),
      ),
    );
  }
}

class DetailPage extends SingleControlWidget<DetailController>
    with RouteControl {
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
            builder: (context, done) =>
                Checkbox(value: done, onChanged: item.changeState),
          ),
          Text(item.title),
        ],
      ),
    );
  }
}
