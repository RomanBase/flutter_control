import 'package:firebase_auth/firebase_auth.dart';

class FirebaseControl {
  FirebaseUser _user;

  FirebaseUser get user => _user;

  Future<FirebaseUser> restoreUser() async => _user = await FirebaseAuth.instance.currentUser();

  Future<FirebaseUser> login(String username, String password) async {
    final response = await FirebaseAuth.instance.signInWithEmailAndPassword(email: username, password: password);

    return _user = response.user;
  }

  Future<FirebaseUser> register(String username, String password, String nickname) async {
    final response = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: username, password: password);

    _user = response.user;

    if (_user != null) {
      _user.updateProfile(UserUpdateInfo()..displayName = nickname);
    }

    return _user;
  }

  Future<void> logout() {
    _user = null;
    return FirebaseAuth.instance.signOut();
  }
}
