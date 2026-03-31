import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserRoleService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static Future<String> getCurrentUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'user';

    final snap = await _db.collection('users').doc(user.uid).get();
    final data = snap.data() ?? {};
    return (data['role'] ?? 'user').toString();
  }

  static Future<bool> isAdminOrModerator() async {
    final role = await getCurrentUserRole();
    return role == 'admin' || role == 'moderator';
  }
}