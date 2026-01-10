part of flutter_control;

class _WidgetTicker extends Ticker {
  _TickerProvider? _creator;

  bool get isMounted => _creator != null;

  _WidgetTicker(TickerCallback onTick, this._creator, {String? debugLabel})
      : super(onTick, debugLabel: debugLabel);

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

  void _muteTicker(bool muted) =>
      _tickers?.forEach((item) => item.muted = muted);

  void stopTicker() => _tickers?.forEach((item) => item.stop());

  @override
  void dispose() {
    assert(() {
      if (_tickers != null) {
        for (Ticker ticker in _tickers!) {
          if (ticker.isActive) {
            throw FlutterError.fromParts(<DiagnosticsNode>[
              ErrorSummary('$this was disposed with an active Ticker.'),
              ErrorDescription(
                  '$runtimeType created a Ticker via its TickerProviderStateMixin, but at the time '
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

/// Extension hook on [CoreContext] to provide a [TickerProvider].
extension TickerHook on CoreContext {
  /// Returns a [TickerProvider] that is hooked to the lifecycle of the [CoreContext].
  _TickerProvider get ticker => use<_TickerProvider>(value: () {
        final provider = _TickerProvider();
        provider._muteTicker(TickerMode.of(this));

        return provider;
      });
}

/// A mixin for a [ControlModel] that requires a [TickerProvider].
///
/// This mixin allows a `ControlModel` to create and manage `AnimationController`s
/// by gaining access to a `TickerProvider` from the hosting widget.
mixin TickerComponent on ControlModel {
  /// The active [TickerProvider]. Can be from a different [ControlModel].
  TickerProvider? _ticker;

  /// Returns the active [TickerProvider].
  @protected
  TickerProvider? get ticker => _ticker;

  /// Checks if a [TickerProvider] is available.
  bool get isTickerAvailable => _ticker != null;

  @override
  void mount(dynamic object) {
    super.mount(object);

    if (object is CoreState) {
      provideTicker(object.element.ticker);
    }
  }

  /// Sets the [TickerProvider]. Called by the framework during [State]
  /// initialization when used with a [CoreWidget].
  void provideTicker(TickerProvider ticker) {
    _ticker = ticker;

    onTickerInitialized(ticker);
  }

  /// Callback after [provideTicker] is executed.
  ///
  /// This is the ideal place to create [AnimationController]s and set up initial animations.
  void onTickerInitialized(TickerProvider ticker);

  @override
  void dispose() {
    super.dispose();

    _ticker = null;
  }
}
