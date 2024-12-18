import 'dart:math';

import 'package:control_core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

final factory = Control.factory;

final broadcast = Control.broadcast;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final isInitialized = Control.initControl(
    debug: false,
    entries: {
      ControlModel: BaseControl(),
      _InjectModel: _InjectModel(),
      'key': 'value',
    },
    factories: {
      _ArgModel: (_) => _ArgModel<String>(),
      _InjectModel: (_) => _InjectModel(),
      _InitNullable: (_) => Random().nextBool() ? null : _InitNullable(),
    },
  );

  group('Control', () {
    test('set up', () async {
      expect(isInitialized, isTrue);

      final reInit = Control.initControl();

      expect(reInit, isFalse);
    });

    test('init', () {
      expect(Control.isInitialized, isTrue);
      expect(Control.isInitialized, factory.isInitialized);

      expect(Control.factory, isNotNull);
      expect(Control.broadcast, isNotNull);

      expect(Control.debug, isFalse);
      expect(Control.debug, factory.debug);

      Control.factory.debug = true;
      expect(Control.debug, isTrue);
    });
  });

  group('Control Factory', () {
    test('instance', () {
      expect(factory, isNotNull);

      final reInit = factory.initialize();

      expect(reInit, isFalse);
    });

    test('set', () {
      final exactKey = factory.set(key: 'string', value: 'value');
      final exactTypeKey = factory.set(key: String, value: 'value');

      expect(exactKey, 'string');
      expect(exactTypeKey, String);

      final autoKey = factory.set(value: ActionControl.empty(broadcast: false));
      final typeKey = factory.set<FieldControl>(value: FieldControl());

      expect(autoKey, ActionControl);
      expect(typeKey, FieldControl);
    });

    test('get', () {
      final itemByType = factory.get<ControlModel>();
      final itemByKey = factory.get(key: ControlModel);
      final itemBySKey = factory.get(key: 'key');
      final itemByExactType = factory.get<BaseControl>()!;

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemBySKey, 'value');
      expect(itemByExactType, isNotNull);

      expect(itemByExactType.isInitialized, isTrue);

      expect(itemByType == itemByKey, isTrue);
      expect(itemByType.runtimeType, BaseControl);

      final itemInit = factory.init<_ArgModel>(args: 'init')!;
      final itemGetInit = factory.get<_ArgModel>(args: 'init')!;

      expect(itemInit.value, 'init');
      expect(itemGetInit.value, 'init');

      final itemInject = factory.get<_InjectModel>()!;

      expect(itemInject.initValue, isNotNull);
      expect(itemInject.itemValue, isNotNull);

      print(Control.get<_InitNullable>() ?? 'nullable ok');
    });

    test('resolve', () {
      final data = {'0': 'item', ControlModel: _InitModel()};

      final item = factory.resolve<String>(data, defaultValue: () => 'def');
      final model = factory.resolve(data, key: ControlModel, args: 'init');
      final argModel = factory.resolve<_ArgModel>(data, args: 'init')!;
      final def = factory.resolve(data, key: 'none', defaultValue: () => 'def');
      final defStore = factory.get(key: 'none');

      expect(item, 'item');

      expect(model, isNotNull);
      expect(model is ControlModel, isTrue);
      expect((model as _InitModel).data, isNull);

      expect(argModel, isNotNull);
      expect(argModel.value, 'init');

      expect(def, 'def');
      expect(defStore, isNull);
    });

    test('swap', () {
      factory.set(key: ControlModel, value: _SwapController());

      final itemByType = factory.get<ControlModel>();
      final itemByKey = factory.get(key: ControlModel);
      final itemByExactType = factory.get<BaseControl>();

      expect(itemByType, isNotNull);
      expect(itemByKey, isNotNull);
      expect(itemByExactType, isNotNull);

      expect(itemByType.runtimeType, _SwapController);
    });
  });

  group('Broadcast', () {
    test('instance', () {
      expect(broadcast, isNotNull);
    });

    test('value', () {
      final sub1 = broadcast.subscribeTo(
          'sub', (value) => expect(value.toString(), '1'));
      final sub2 =
          broadcast.subscribeTo<int>('sub', (value) => expect(value, 1));
      final sub3 = broadcast.subscribeTo(
          String, (value) => expect(value.toString(), '2'));
      final sub4 =
          broadcast.subscribeTo<String>(String, (value) => expect(value, '2'));
      final sub5 = broadcast.subscribeTo(
          'notnull', (value) => expect(value, isNotNull),
          nullOk: false);

      expect(sub1.isValidForBroadcast('sub', 'string'), isTrue);
      expect(sub1.isValidForBroadcast('sub', 1), isTrue);

      expect(sub2.isValidForBroadcast('sub', 2), isTrue);
      expect(sub2.isValidForBroadcast('sub', '2'), isFalse);

      expect(sub3.isValidForBroadcast(String, '3'), isTrue);
      expect(sub3.isValidForBroadcast(String, 3), isTrue);

      expect(sub4.isValidForBroadcast(String, '4'), isTrue);
      expect(sub4.isValidForBroadcast(String, 4), isFalse);

      expect(sub5.isValidForBroadcast('notnull', '5'), isTrue);
      expect(sub5.isValidForBroadcast('notnull', null), isFalse);

      final count1 = broadcast.broadcast(key: 'sub', value: '1');
      final count2 = broadcast.broadcast(key: 'sub', value: 1);

      final count3 = broadcast.broadcast(key: String, value: '2');
      final count4 = broadcast.broadcast(key: String, value: 2);

      final count5 = broadcast.broadcast(key: 'notnull', value: null);
      final count6 = broadcast.broadcast(key: 'notnull', value: 'value');

      expect(count1, 1);
      expect(count2, 2);
      expect(count3, 2);
      expect(count4, 1);
      expect(count5, 0);
      expect(count6, 1);

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

      final count1 = broadcast.broadcastEvent(key: 'sub');
      final count2 = broadcast.broadcastEvent(key: String);

      expect(count1, 1);
      expect(count2, 1);

      sub2.cancel();
      sub3.cancel();

      final count3 = broadcast.broadcastEvent(key: String);

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
  T? value;

  @override
  void init(Map args) {
    super.init(args);

    value = Parse.getArg<T>(args);
  }
}

class _InjectModel extends _InitModel {
  BaseModel? initValue;
  BaseControl? itemValue;

  @override
  void init(Map args) {
    super.init(args);

    initValue = factory.init<_ArgModel>();
    itemValue = factory.get<BaseControl>();
  }
}

class _InitNullable extends BaseModel {
  dynamic data;
}

class _SwapController extends BaseControl {}
