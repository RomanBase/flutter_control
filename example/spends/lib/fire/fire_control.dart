import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_control/core.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FireProvider {
  FireControl get fire => Control.get<FireControl>();
}

class FireControl {
  final _user = ActionControl.broadcast<FirebaseUser>();

  FirebaseUser get user => _user.value;

  bool get isUserSignedIn => _user.isNotEmpty;

  String get uid => _user.value?.uid;

  ActionControlObservable<FirebaseUser> get userSub => _user.sub;

  Future<FirebaseUser> signUp(
      String email, String password, String nickname) async {
    final user = await FirebaseAuth.instance
        .createUserWithEmailAndPassword(email: email, password: password);

    final info = UserUpdateInfo()..displayName = nickname;

    await user.user.updateProfile(info);

    return _user.value = user.user;
  }

  Future<FirebaseUser> signIn(String email, String password) async {
    final user = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);

    return _user.value = user.user;
  }

  Future<FirebaseUser> restore() async =>
      _user.value = await FirebaseAuth.instance.currentUser();

  Future<FirebaseUser> signInWithGoogle() async {
    final google = GoogleSignIn(scopes: [
      'email',
    ]);

    final acc = await google.signIn().catchError((err) {
      print(err);
    });

    if (acc == null) {
      return null;
    }

    final auth = await acc.authentication;
    final credential = GoogleAuthProvider.getCredential(
        idToken: auth.idToken, accessToken: auth.accessToken);

    final user = await FirebaseAuth.instance.signInWithCredential(credential);

    await google.signOut();

    return _user.value = user.user;
  }

  Future<void> signOut() async {
    _user.value = null;
    return FirebaseAuth.instance.signOut();
  }

  Future<void> requestPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
