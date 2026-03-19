import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
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
          .where('username', isEqualTo: username.toLowerCase)
          //.where('username', isEqualTo: username)
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


  /*// handles username and email login
  Future<String?> hybridLogin({
    required String identifier,
    required String password,
  }) async {
    try {
      String email = identifier;

      if (!identifier.contains('@')) {
        // --- DEBUG LINE 1: See if the function is starting ---
        print("DEBUG: Identifying '$identifier' as a username. Starting search...");

        final userQuery = await _db
            .collection('users')
            .where('username', isEqualTo: identifier.trim().toLowerCase())
            .limit(1)
            .get();

        // --- DEBUG LINE 2: See if Firestore actually found anything ---
        if (userQuery.docs.isEmpty) {
          print("DEBUG: Search failed. No user found with username: $identifier");
          return 'Username not found.';
        }

        // --- DEBUG LINE 3: See the email we grabbed ---
        email = userQuery.docs.first.get('email');
        print("DEBUG: Success! Found email: $email. Proceeding to login...");
      }

      // Attempting the actual login
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      print("DEBUG: Login successful for $email");
      return 'Success';

    } on FirebaseAuthException catch (e) {
      // --- DEBUG LINE 4: Catch Firebase specific errors (like wrong password) ---
      print("DEBUG: FirebaseAuth Error: ${e.code} - ${e.message}");
      if (e.code == 'user-not-found') return 'No user found for that email.';
      if (e.code == 'wrong-password') return 'Incorrect password.';
      return e.message;
    } catch (e) {
      // --- DEBUG LINE 5: Catch "Permission Denied" or Database errors ---
      print("DEBUG: Critical Error: $e");
      return e.toString();
    }
  }*/
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
            .where('username', isEqualTo: identifier.trim().toLowerCase)
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