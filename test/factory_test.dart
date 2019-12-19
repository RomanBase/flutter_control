import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore: non_constant_identifier_names
final _FACTORY = ControlFactory.of(null);

// ignore: non_constant_identifier_names
final _BROADCAST = _FACTORY.get<ControlBroadcast>();

void main() {
  _FACTORY.initialize(
    items: {
      BaseControlModel: BaseController(),
      _InjectModel: _InjectModel(),
      'key': 'value',
    },
    initializers: {
      _ArgModel: (_) => _ArgModel<String>(),
      _InjectModel: (_) => _InjectModel(),
    },
  );

  group('Control Factory', () {
    test('instance', () {
      expect(_FACTORY, isNotNull);
    });

    test('get', () {
      final itemByType = _FACTORY.get<BaseControlModel>();
      final itemByKey = _FACTORY.get(BaseControlModel);
      final itemBySKey = _FACTORY.get('key');
      final itemByExactType = _FACTORY.get<BaseController>();

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemBySKey, 'value');
      expect(itemByExactType, isNotNull);

      expect(itemByExactType.isInitialized, isTrue);

      expect(itemByType == itemByKey, isTrue);
      expect(itemByType.runtimeType, BaseController);

      final itemInit = _FACTORY.init<_ArgModel>('init');
      final itemGetInit = _FACTORY.get<_ArgModel>('init');

      expect(itemInit.value, 'init');
      expect(itemGetInit.value, 'init');

      final itemInject = _FACTORY.get<_InjectModel>();

      expect(itemInject.initValue, isNotNull);
      expect(itemInject.itemValue, isNotNull);
    });

    test('set', () {
      final exactKey = _FACTORY.set(key: 'string', value: 'value');
      final exactTypeKey = _FACTORY.set(key: String, value: 'value');

      expect(exactKey, 'string');
      expect(exactTypeKey, String);

      final autoKey = _FACTORY.set(value: ActionControl.single());
      final typeKey = _FACTORY.set<FieldControl>(value: FieldControl());

      expect(autoKey, ActionControl);
      expect(typeKey, FieldControl);
    });

    test('swap', () {
      _FACTORY.set(key: BaseControlModel, value: _SwapController());

      final itemByType = _FACTORY.get<BaseControlModel>();
      final itemByKey = _FACTORY.get(BaseControlModel);
      final itemByExactType = _FACTORY.get<BaseController>();

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemByExactType, isNotNull);

      expect(itemByType.runtimeType, _SwapController);
    });

    test('inject', () {
      final injector = _FACTORY.get<Injector>() as BaseInjector;

      injector.setInjector<_InjectModel>((item, args) {
        item.data = _ArgModel();
      });

      injector.setInjector((item, args) {
        if (item is _InitModel) {
          item.data = args;
        }
      });

      final item = _FACTORY.init<_InjectModel>();
      final itemBase = _InitModel();

      injector.inject(itemBase, 'init');

      expect(item.data.runtimeType, _ArgModel);
      expect(itemBase.data, 'init');
    });
  });

  group('Broadcast', () {
    test('instance', () {
      expect(_BROADCAST, isNotNull);
    });

    test('value', () {
      final sub1 = _BROADCAST.subscribe('sub', (value) => expect(value.toString(), '1'));
      final sub2 = _BROADCAST.subscribe<int>('sub', (value) => expect(value, 1));
      final sub3 = _BROADCAST.subscribe(String, (value) => expect(value.toString(), '2'));
      final sub4 = _BROADCAST.subscribe<String>(String, (value) => expect(value, '2'));

      expect(sub1.isValidForBroadcast('sub', 'string'), isTrue);

      expect(sub2.isValidForBroadcast('sub', 100), isTrue);
      expect(sub2.isValidForBroadcast('sub', '100'), isFalse);

      expect(sub3.isValidForBroadcast(String, 'string'), isTrue);
      expect(sub3.isValidForBroadcast(String, 100), isTrue);

      expect(sub4.isValidForBroadcast(String, 'string'), isTrue);
      expect(sub4.isValidForBroadcast(String, 100), isFalse);

      final count1 = _BROADCAST.broadcast('sub', '1');
      final count2 = _BROADCAST.broadcast('sub', 1);

      final count3 = _BROADCAST.broadcast(String, '2');
      final count4 = _BROADCAST.broadcast(String, 2);

      expect(count1, 1);
      expect(count2, 2);
      expect(count3, 2);
      expect(count4, 1);

      _BROADCAST.clear();
      expect(_BROADCAST.subCount, 0);
    });

    test('event', () {
      final sub1 = _BROADCAST.subscribeEvent('sub', () {});
      final sub2 = _BROADCAST.subscribeEvent(String, () {});
      final sub3 = _BROADCAST.subscribeEvent('String', () {});

      expect(sub1.isValidForBroadcast('sub', null), isTrue);
      expect(sub2.isValidForBroadcast(String, null), isTrue);
      expect(sub2.isValidForBroadcast('sub', null), isFalse);

      final count1 = _BROADCAST.broadcastEvent('sub');
      final count2 = _BROADCAST.broadcastEvent(String);

      expect(count1, 1);
      expect(count2, 1);

      sub2.cancel();
      sub3.cancel();

      final count3 = _BROADCAST.broadcastEvent(String);

      expect(count3, 0);
      expect(sub3.isActive, isFalse);

      _BROADCAST.clear();
      expect(_BROADCAST.subCount, 0);
    });
  });

  group('Clean up', () {
    test('clear', () {
      _FACTORY.dispose();

      expect(_FACTORY.isInitialized, isFalse);
      expect(_BROADCAST.subCount, 0);
    });
  });
}

class _InitModel extends BaseModel {
  dynamic data;
}

class _ArgModel<T> extends BaseModel {
  T value;

  @override
  void init(Map args) {
    super.init(args);

    value = Parse.getArg<T>(args);
  }
}

class _InjectModel extends _InitModel {
  BaseModel initValue;
  BaseController itemValue;

  @override
  void init(Map args) {
    super.init(args);

    initValue = _FACTORY.init<_ArgModel>();
    itemValue = _FACTORY.get<BaseController>();
  }
}

class _SwapController extends BaseController {}
