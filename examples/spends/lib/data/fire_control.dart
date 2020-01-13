import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_control/core.dart';
import 'package:google_sign_in/google_sign_in.dart';

var firebaseConfig = {
  'apiKey': "AIzaSyAbYJiHnpb2hWANjFaxVpz-E51RUZVxfgw",
  'authDomain': "base-control-fire.firebaseapp.com",
  'databaseURL': "https://base-control-fire.firebaseio.com",
  'projectId': "base-control-fire",
  'storageBucket': "base-control-fire.appspot.com",
  'messagingSenderId': "542744611210",
  'appId': "1:542744611210:web:c458c579272061cea5e073",
  'googleAppID': "542744611210",
  'measurementId': "G-H9CVM1FL5F"
};

class FireProvider {
  FireControl get fire => Control.get<FireControl>();
}

class FireControl {
  FirebaseUser _user;

  FirebaseUser get user => _user;

  bool get isUserSignedIn => _user != null;

  static Future init() async {
    return FirebaseApp.configure(
      name: 'Spend',
      options: FirebaseOptions.from(firebaseConfig),
    );
  }

  Future<FirebaseUser> signUp(String email, String password, String nickname) async {
    final user = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

    final info = UserUpdateInfo()..displayName = nickname;

    await user.user.updateProfile(info);

    return _user = user.user;
  }

  Future<FirebaseUser> signIn(String email, String password) async {
    final user = await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

    return _user = user.user;
  }

  Future<FirebaseUser> restore() async => _user = await FirebaseAuth.instance.currentUser();

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
    final credential = GoogleAuthProvider.getCredential(idToken: auth.idToken, accessToken: auth.accessToken);

    final user = await FirebaseAuth.instance.signInWithCredential(credential);

    await google.signOut();

    return _user = user.user;
  }

  Future<void> signOut() async {
    _user = null;
    return FirebaseAuth.instance.signOut();
  }

  Future<void> requestPasswordReset(String email) {
    return FirebaseAuth.instance.sendPasswordResetEmail(email: email);
  }
}
