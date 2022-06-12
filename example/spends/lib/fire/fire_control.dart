import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_control/control.dart';
import 'package:spends/fire/fire_provider.dart';

class FireProvider {
  FireControl get fire => Control.get<FireControl>();
}

class FireControl {
  final _user = ActionControl.empty<User>();

  User get user => _user.value;

  bool get isUserSignedIn => _user.isNotEmpty;

  String get uid => _user.value?.uid;

  ObservableModel<User> get userSub => _user;

  Future<User> signUp(String email, String password, String nickname) async {
    final user = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    await user.user.updateProfile(displayName: nickname);

    return _user.value = user.user;
  }

  Future<User> signIn(String email, String password) async {
    final user = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    return _user.value = user.user;
  }

  Future<User> restore() async {
    await FirebaseProvider
        .initialize(); // init firebase app + edit android/app/build.gradle applicationId

    _user.value = FirebaseAuth.instance.currentUser;

    return _user.value;
  }

  Future<User> signInWithGoogle() async {
    /*final google = GoogleSignIn(scopes: [
      'email',
    ]);

    final acc = await google.signIn().catchError((err) {
      print(err);
    });

    if (acc == null) {
      return null;
    }

    final auth = await acc.authentication;

    final user = await FirebaseAuth.instance.signinwi(idToken: auth.idToken, accessToken: auth.accessToken);

    await google.signOut();

    return _user.value = user;*/
  }

  Future<void> signOut() async {
    _user.value = null;
    return FirebaseAuth.instance.signOut();
  }

  Future<void> requestPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
