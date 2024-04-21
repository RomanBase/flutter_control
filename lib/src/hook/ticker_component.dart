part of flutter_control;

class _WidgetTicker extends Ticker {
  _TickerProvider? _creator;

  bool get isMounted => _creator != null;

  _WidgetTicker(TickerCallback onTick, this._creator, {String? debugLabel}) : super(onTick, debugLabel: debugLabel);

  @override
  void dispose() {
    _creator?._removeTicker(this);
    _creator = null;

    super.dispose();
  }
}

class _TickerProvider implements Disposable, TickerProvider {
  Set<Ticker>? _tickers;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _tickers ??= <_WidgetTicker>{};

    final ticker = _WidgetTicker(onTick, this, debugLabel: 'created by $this');
    _tickers!.add(ticker);

    return ticker;
  }

  void _removeTicker(_WidgetTicker ticker) {
    if (_tickers == null) {
      return;
    }

    _tickers!.remove(ticker);
  }

  void _muteTicker(bool muted) => _tickers?.forEach((item) => item.muted = muted);

  void _stop() => _tickers?.forEach((item) => item.stop());

  @override
  void dispose() {
    _stop();

    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription('$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
                  'dispose() was called on the mixin, that Ticker was still active. All Tickers must '
                  'be disposed before calling super.dispose().'),
              ErrorHint('Tickers used by AnimationControllers '
                  'should be disposed by calling dispose() on the AnimationController itself. '
                  'Otherwise, the ticker will leak.'),
              ticker.describeForError('The offending ticker was'),
            ]);
          }
        }
      }
      return true;
    }());

    _tickers?.clear();
    _tickers = null;
  }
}

extension TickerHook on CoreContext {
  _TickerProvider get ticker => use<_TickerProvider>(value: () {
        final provider = _TickerProvider();
        provider._muteTicker(TickerMode.of(this));

        return provider;
      })!;
}

mixin TickerComponent on ControlModel {
  /// Active provider. In fact provider can be used from different [ControlModel].
  TickerProvider? _ticker;

  /// Returns active [TickerProvider] provided by Widget or passed by other Control.
  @protected
  TickerProvider? get ticker => _ticker;

  /// Checks if [TickerProvider] is set.
  bool get isTickerAvailable => _ticker != null;

  @override
  void register(dynamic object) {
    super.register(object);

    if (object is CoreState) {
      provideTicker(object.element.ticker);
    }
  }

  /// Sets vsync. Called by framework during [State] initialization when used with [CoreWidget] and [TickerControl].
  void provideTicker(TickerProvider ticker) {
    _ticker = ticker;

    onTickerInitialized(ticker);
  }

  /// Callback after [provideTicker] is executed.
  /// Serves to created [AnimationController] and to set initial animation state.
  void onTickerInitialized(TickerProvider ticker);

  @override
  void dispose() {
    super.dispose();

    _ticker = null;
  }
}
