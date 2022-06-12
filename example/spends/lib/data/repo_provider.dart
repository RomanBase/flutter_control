import 'package:flutter_control/control.dart';
import 'package:spends/data/earnings_repo.dart';
import 'package:spends/data/spend_repo.dart';

mixin RepoProvider {
  SpendRepo _spendRepo;

  SpendRepo get spendRepo =>
      _spendRepo ?? (_spendRepo = Control.init<SpendRepo>());

  EarningsRepo _earningsRepo;

  EarningsRepo get earningsRepo =>
      _earningsRepo ?? (_earningsRepo = Control.init<EarningsRepo>());

  static Map<Type, Initializer> initializers({
    @required Initializer<SpendRepo> spendRepo,
    @required Initializer<EarningsRepo> earningsRepo,
  }) =>
      {
        SpendRepo: spendRepo,
        EarningsRepo: earningsRepo,
      };
}
