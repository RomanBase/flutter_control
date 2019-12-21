import 'package:flutter_control/core.dart';
import 'package:flutter_test/flutter_test.dart';

final factory = ControlFactory.of(null);

final broadcast = factory.get<ControlBroadcast>();

void main() {
  factory.initialize(
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
      expect(factory, isNotNull);
    });

    test('get', () {
      final itemByType = factory.get<BaseControlModel>();
      final itemByKey = factory.get(BaseControlModel);
      final itemBySKey = factory.get('key');
      final itemByExactType = factory.get<BaseController>();

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemBySKey, 'value');
      expect(itemByExactType, isNotNull);

      expect(itemByExactType.isInitialized, isTrue);

      expect(itemByType == itemByKey, isTrue);
      expect(itemByType.runtimeType, BaseController);

      final itemInit = factory.init<_ArgModel>('init');
      final itemGetInit = factory.get<_ArgModel>('init');

      expect(itemInit.value, 'init');
      expect(itemGetInit.value, 'init');

      final itemInject = factory.get<_InjectModel>();

      expect(itemInject.initValue, isNotNull);
      expect(itemInject.itemValue, isNotNull);
    });

    test('set', () {
      final exactKey = factory.set(key: 'string', value: 'value');
      final exactTypeKey = factory.set(key: String, value: 'value');

      expect(exactKey, 'string');
      expect(exactTypeKey, String);

      final autoKey = factory.set(value: ActionControl.single());
      final typeKey = factory.set<FieldControl>(value: FieldControl());

      expect(autoKey, ActionControl);
      expect(typeKey, FieldControl);
    });

    test('swap', () {
      factory.set(key: BaseControlModel, value: _SwapController());

      final itemByType = factory.get<BaseControlModel>();
      final itemByKey = factory.get(BaseControlModel);
      final itemByExactType = factory.get<BaseController>();

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemByExactType, isNotNull);

      expect(itemByType.runtimeType, _SwapController);
    });

    test('inject', () {
      final injector = factory.get<Injector>() as BaseInjector;

      injector.setInjector<_InjectModel>((item, args) {
        item.data = _ArgModel();
      });

      injector.setInjector((item, args) {
        if (item is _InitModel) {
          item.data = args;
        }
      });

      final item = factory.init<_InjectModel>();
      final itemBase = _InitModel();

      injector.inject(itemBase, 'init');

      expect(item.data.runtimeType, _ArgModel);
      expect(itemBase.data, 'init');
    });
  });

  group('Broadcast', () {
    test('instance', () {
      expect(broadcast, isNotNull);
    });

    test('value', () {
      final sub1 = broadcast.subscribe('sub', (value) => expect(value.toString(), '1'));
      final sub2 = broadcast.subscribe<int>('sub', (value) => expect(value, 1));
      final sub3 = broadcast.subscribe(String, (value) => expect(value.toString(), '2'));
      final sub4 = broadcast.subscribe<String>(String, (value) => expect(value, '2'));

      expect(sub1.isValidForBroadcast('sub', 'string'), isTrue);

      expect(sub2.isValidForBroadcast('sub', 100), isTrue);
      expect(sub2.isValidForBroadcast('sub', '100'), isFalse);

      expect(sub3.isValidForBroadcast(String, 'string'), isTrue);
      expect(sub3.isValidForBroadcast(String, 100), isTrue);

      expect(sub4.isValidForBroadcast(String, 'string'), isTrue);
      expect(sub4.isValidForBroadcast(String, 100), isFalse);

      final count1 = broadcast.broadcast('sub', '1');
      final count2 = broadcast.broadcast('sub', 1);

      final count3 = broadcast.broadcast(String, '2');
      final count4 = broadcast.broadcast(String, 2);

      expect(count1, 1);
      expect(count2, 2);
      expect(count3, 2);
      expect(count4, 1);

      broadcast.clear();
      expect(broadcast.subCount, 0);
    });

    test('event', () {
      final sub1 = broadcast.subscribeEvent('sub', () {});
      final sub2 = broadcast.subscribeEvent(String, () {});
      final sub3 = broadcast.subscribeEvent('String', () {});

      expect(sub1.isValidForBroadcast('sub', null), isTrue);
      expect(sub2.isValidForBroadcast(String, null), isTrue);
      expect(sub2.isValidForBroadcast('sub', null), isFalse);

      final count1 = broadcast.broadcastEvent('sub');
      final count2 = broadcast.broadcastEvent(String);

      expect(count1, 1);
      expect(count2, 1);

      sub2.cancel();
      sub3.cancel();

      final count3 = broadcast.broadcastEvent(String);

      expect(count3, 0);
      expect(sub3.isActive, isFalse);

      broadcast.clear();
      expect(broadcast.subCount, 0);
    });
  });

  group('Clean up', () {
    test('clear', () {
      factory.dispose();

      expect(factory.isInitialized, isFalse);
      expect(broadcast.subCount, 0);
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

    initValue = factory.init<_ArgModel>();
    itemValue = factory.get<BaseController>();
  }
}

class _SwapController extends BaseController {}
