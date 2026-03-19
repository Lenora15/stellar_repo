import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instance(
    app: Firebase.app(),
    databaseId: 'user-info',
  );

  //save data to firebase
  Future<String?> registration({
    required String email,
    required String password,
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    DateTime? birthDate,
  }) async {
    try {
      //check if username is taken
      final usernameCheck = await _db
          .collection('user-info')
          .where('username', isEqualTo: username)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        return 'This username is already taken.';
      }

      //create user within firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      String uid = userCredential.user!.uid;

      //save metadata to uid
      await _db.collection('user-info').doc(uid).set({
        'uid': uid,
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate != null ? Timestamp.fromDate(birthDate) : null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'phone': phone,
      });

      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  //handles username and email
  Future<String?> hybridLogin({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier;

      //input is treated like a username if it doesnt look like an email address
      if (!identifier.contains('@')) {
        final userQuery = await _db
            .collection('users')
            .where('username', isEqualTo: identifier)
            .limit(1)
            .get();

        if (userQuery.docs.isEmpty) {
          return 'Username not found.';
        }
        email = userQuery.docs.first.get('email');
      }

      //use email to login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return 'Success';
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Incorrect password.';
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

 //password reset
  Future<String?> resetPassword({required String email}) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      return 'Success';
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }
}