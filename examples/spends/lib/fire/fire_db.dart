import 'package:cloud_firestore/cloud_firestore.dart';

import 'fire_control.dart';

class FireDB with FireProvider {
  DocumentReference get root => Firestore.instance.document('examples/spend');

  DocumentReference dataRef() => root.collection('data').document(fire.uid);
}
