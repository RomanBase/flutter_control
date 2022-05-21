import 'package:flutter_control/core.dart';

import 'cards_page.dart';

class CardsController extends BaseControl
    with RouteNavigatorProvider, LocalinoProvider {
  final cards = ListControl<CardModel>();
  final countLabel = StringControl();
  final input = InputControl();

  int _counter = 0;

  @override
  bool get preventDispose => true;

  CardsController() {
    cards.subscribe((value) => countLabel.setValue('${value.length}'));
  }

  @override
  void onInit(Map args) {
    super.onInit(args);

    BroadcastProvider.subscribe<CardModel>(
        'remove_card', (card) => removeCard(card));
  }

  void addCard() {
    String title = input.isEmpty
        ? '${localize('card_title')} $_counter${localizePlural('number', _counter)}'
        : input.text;

    newCard(title);

    input.clear();

    _counter++;
  }

  CardModel newCard(String title) {
    if (title == null || title.isEmpty) {
      return null; //TODO: show error
    }

    final card = CardModel(title);

    cards.add(card);

    return card;
  }

  void removeCard(CardModel item) => cards.remove(item);

  openCard(CardModel item) => ControlRoute.of<DetailPage>()
      .navigator(navigator)
      .openRoute(args: {'card': item});

  @override
  void dispose() {
    super.dispose();

    cards.clear(disposeItems: true);
    cards.dispose();

    countLabel.dispose();
    input.dispose();
  }
}

class DetailController extends BaseControl
    with RouteNavigatorProvider, LocalinoProvider {
  CardModel _model;

  ListControl<CardItemModel> get items => _model.items;

  final title = StringControl();

  DetailController([CardModel model]) {
    _model = model;
  }

  @override
  void onInit(Map args) {
    super.onInit(args);

    _model ??= args.getArg<CardModel>();

    title.subscribeTo(_model.countLabel.stream,
        converter: (input) => '${_model.title} - $input');
  }

  void addItem() => newItem('${localize('item_title')} ${items.length}');

  CardItemModel newItem(String title) {
    if (title == null || title.isEmpty) {
      return null; //TODO: show error
    }

    final item = CardItemModel(_model, title);

    items.add(item);

    return item;
  }

  void deleteSelf() {
    BroadcastProvider.broadcast(key: 'remove_card', value: _model);
    navigator.close();
  }

  @override
  void dispose() {
    super.dispose();

    title.dispose();
  }
}

class CardModel extends BaseModel
    with LocalinoProvider, ObservableComponent {
  final String title;
  final countLabel = StringControl();
  final progress = ControlObservable.empty<double>();
  final items = ListControl<CardItemModel>();

  CardModel(this.title) {
    items.subscribe(
      (list) => _updateProgress(),
      current: false,
    );
  }

  void _updateProgress() {
    final sum = items.length;
    final num = items.where((item) => item.done.isTrue).length;

    if (sum == 0) {
      countLabel.setValue(null);
      progress.setValue(0.0);
      return;
    }

    countLabel.setValue('$num/$sum');
    progress.setValue(num / sum);

    notify();
  }

  @override
  void dispose() {
    super.dispose();

    countLabel.dispose();
    progress.dispose();

    items.clear(disposeItems: true);
    items.dispose();
  }
}

class CardItemModel extends BaseModel {
  final String title;
  final done = ActionControl.empty<bool>();

  CardItemModel(CardModel parent, this.title) {
    done.subscribe((value) => parent._updateProgress());
  }

  void changeState(bool value) => done.setValue(value);

  void toggle() => done.toggle();

  @override
  void dispose() {
    super.dispose();

    done.dispose();
  }
}
