import 'package:flutter_control/core.dart';
import 'package:spends/control/init_control.dart';
import 'package:spends/fire/fire_control.dart';
import 'package:spends/theme.dart';
import 'package:spends/widget/button.dart';
import 'package:spends/widget/input_decoration.dart';

class _UIControl extends ControlModel with FireProvider, TickerComponent {
  final signMode = ActionControl.broadcast<SignMode>(SignMode.sign_in);
  SignMode prevMode = SignMode.sign_in;

  InitControl control;

  AnimationController fieldAnim;
  AnimationController loadingAnim;
  AnimationController transferAnim;

  @override
  void init(Map args) {
    control = args.getArg<InitControl>();

    assert(control != null);
  }

  @override
  void onTickerInitialized(TickerProvider ticker) {
    final theme = ThemeProvider.of();
    fieldAnim = AnimationController(vsync: ticker, duration: theme.animDuration);
    loadingAnim = AnimationController(vsync: ticker, duration: theme.animDurationSlow);
    transferAnim = AnimationController(vsync: ticker, duration: theme.animDurationSecond);

    loadingAnim.value = 1.0;

    control.loading.subscribe((value) {
      switch (value) {
        case LoadingStatus.progress:
          loadingAnim.forward();
          break;
        case LoadingStatus.done:
          if (control.loading.message is SignMode) {
            setSignMode(control.loading.message);
            loadingAnim.reverse();
            break;
          }

          if (fire.isUserSignedIn) {
            transferToApp();
          } else {
            loadingAnim.reverse();
          }
          break;
        case LoadingStatus.error:
          //TODO: show error message.
          loadingAnim.reverse();
          break;
        case LoadingStatus.initial:
        case LoadingStatus.outdated:
        case LoadingStatus.unknown:
          loadingAnim.reverse();
      }
    });
  }

  void toggleSignType() => setSignMode(signMode.value == SignMode.sign_in ? SignMode.sign_up : SignMode.sign_in);

  void setSignMode(SignMode mode) {
    if (mode == signMode.value) {
      return;
    }

    prevMode = signMode.value;
    signMode.value = mode;
    fieldAnim.forward(from: 0);

    switch (mode) {
      case SignMode.sign_in:
        control.username.done(null).next(control.password).done(submit);
        break;
      case SignMode.sign_up:
        control.username.done(null).next(control.nickname).next(control.password).done(submit);
        break;
      case SignMode.sign_pass:
        control.username.done(submit);
        break;
    }
  }

  void transferToApp() {
    if (transferAnim != null) {
      transferAnim.forward(from: 0.0);
      transferAnim.addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          control.complete();
        }
      });
    }
  }

  void submit() {
    switch (signMode.value) {
      case SignMode.sign_in:
        control.signIn();
        break;
      case SignMode.sign_up:
        control.signUp();
        break;
      case SignMode.sign_pass:
        control.resetPass();
        break;
    }
  }

  Animation<double> makeTween(List<SignMode> states, SignMode mode) {
    final visible = states.contains(mode);

    if (visible && states.contains(prevMode)) {
      return Tween<double>(begin: 1.0, end: 1.0).animate(fieldAnim);
    }

    if (!visible && !states.contains(prevMode)) {
      return Tween<double>(begin: 0.0, end: 0.0).animate(fieldAnim);
    }

    final begin = visible ? 0.0 : 1.0;

    return Tween<double>(begin: begin, end: 1.0 - begin).animate(CurvedAnimation(parent: fieldAnim, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    super.dispose();

    signMode.dispose();
    fieldAnim?.dispose();
    loadingAnim?.dispose();
    transferAnim?.dispose();
  }
}

class InitPage extends ControlWidget with ThemeProvider<SpendTheme>, TickerControl {
  InitControl get control => controls[0];

  _UIControl get uiControl => controls[1];

  @override
  List<ControlModel> initControls() => [
        getArg<InitControl>(),
        _UIControl(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: <Widget>[
          _wrapToScroll(
            child: ActionBuilder<SignMode>(
              control: uiControl.signMode,
              builder: (context, value) {
                return AnimatedContainer(
                  duration: theme.animDuration,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.gradient,
                      stops: value == SignMode.sign_in ? [0.0, 0.45, 1.0] : [0.0, 0.35, 1.0],
                      begin: value == SignMode.sign_in ? Alignment.bottomLeft : Alignment.bottomRight,
                      end: value == SignMode.sign_in ? Alignment.topRight : Alignment.topLeft,
                    ),
                  ),
                );
              },
            ),
          ),
          // loading circle
          ScaleTransition(
            scale: Tween<double>(begin: 0.65, end: 3.0).animate(CurvedAnimation(parent: uiControl.transferAnim, curve: Curves.easeOut)),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: uiControl.loadingAnim, curve: Curves.easeIn)),
              child: Center(
                child: SizedBox(
                  width: device.width,
                  height: device.width,
                  child: CircularProgressIndicator(
                    backgroundColor: theme.dark,
                  ),
                ),
              ),
            ),
          ),
          // transfer background
          ScaleTransition(
            scale: Tween<double>(begin: 0.0, end: 3.0).animate(CurvedAnimation(parent: uiControl.transferAnim, curve: Curves.easeIn)),
            child: Center(
              child: Container(
                width: device.width,
                height: device.width,
                decoration: BoxDecoration(
                  color: theme.dark,
                  borderRadius: BorderRadius.all(Radius.circular(device.width * 0.5)),
                ),
              ),
            ),
          ),
          //form
          FadeTransition(
            opacity: Tween<double>(begin: 1.0, end: -1.0).animate(CurvedAnimation(parent: uiControl.loadingAnim, curve: Curves.easeIn)),
            child: ListView(
              padding: EdgeInsets.all(theme.paddingExtended),
              physics: BouncingScrollPhysics(),
              children: <Widget>[
                SizedBox(
                  height: 256.0,
                ),
                InputField(
                  control: control.username,
                  decoration: RoundInputDecoration(),
                  textInputAction: TextInputAction.next,
                  label: 'e-mail',
                  cursorColor: theme.white,
                ),
                _fieldSignState(
                  topPadding: theme.paddingMid,
                  states: [SignMode.sign_up],
                  child: InputField(
                    control: control.nickname,
                    decoration: RoundInputDecoration(),
                    textInputAction: TextInputAction.next,
                    label: 'nickname',
                    cursorColor: theme.white,
                  ),
                ),
                _fieldSignState(
                  topPadding: theme.paddingMid,
                  states: [SignMode.sign_in, SignMode.sign_up],
                  child: InputField(
                    control: control.password,
                    obscureText: true,
                    decoration: RoundInputDecoration(),
                    textInputAction: TextInputAction.done,
                    label: 'password',
                    cursorColor: theme.white,
                  ),
                ),
                SizedBox(
                  height: theme.paddingExtended,
                ),
                RoundedButton(
                  onPressed: uiControl.submit,
                  color: theme.dark,
                  child: Text(
                    localize('submit'),
                    style: font.button,
                  ),
                ),
                SizedBox(
                  height: theme.padding,
                ),
                FadeButton(
                  onPressed: uiControl.toggleSignType,
                  child: ActionBuilder<SignMode>(
                    control: uiControl.signMode,
                    builder: (context, value) {
                      final singIn = value == SignMode.sign_in;
                      return RichText(
                        text: TextSpan(
                          text: singIn ? "Don't have account ?" : "Already have account ?",
                          children: [
                            TextSpan(
                              text: ' ',
                            ),
                            TextSpan(
                              text: singIn ? 'Sing Up!' : 'Sign In!',
                              style: font.button,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  height: theme.padding,
                ),
                _fieldSignState(
                  states: [SignMode.sign_in, SignMode.sign_up],
                  child: FadeButton(
                    onPressed: () => uiControl.setSignMode(SignMode.sign_pass),
                    child: Text(
                      'Forgotten password ?',
                      style: font.body2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fieldSignState({List<SignMode> states, @required Widget child, double topPadding: 0.0}) {
    return ActionBuilder<SignMode>(
      control: uiControl.signMode,
      builder: (context, mode) {
        return SizeTransition(
          sizeFactor: uiControl.makeTween(states, mode),
          child: Container(
            padding: EdgeInsets.only(top: topPadding),
            height: theme.buttonHeight + topPadding,
            child: AnimatedOpacity(
              opacity: states.contains(mode) ? 1.0 : 0.0,
              duration: theme.animDurationFast,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _wrapToScroll({@required Widget child}) {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: SizedBox(
        height: device.height,
        child: child,
      ),
    );
  }
}
