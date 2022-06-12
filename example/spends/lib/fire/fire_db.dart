import 'package:cloud_firestore/cloud_firestore.dart';

import 'fire_control.dart';

class FireDB with FireProvider {
  DocumentReference get root =>
      FirebaseFirestore.instance.doc('examples/spend');

  DocumentReference dataRef() => root.collection('data').doc(fire.uid);
}
