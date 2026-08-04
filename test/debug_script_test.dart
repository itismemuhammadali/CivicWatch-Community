import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/firebase/firebase_options.dart';

void main() {
  testWidgets('Dump Firestore data', (WidgetTester tester) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase init error (might be already initialized): $e');
    }
    
    print('--- DEBUG DATA START ---');
    try {
      FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
      final users = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in users.docs) {
        print('USER DOC: ${doc.id} | data: ${doc.data()}');
      }
      final follows = await FirebaseFirestore.instance.collection('follows').get();
      for (var doc in follows.docs) {
        print('FOLLOW DOC: ${doc.id} | data: ${doc.data()}');
      }
    } catch (e) {
      print('DEBUG ERROR: $e');
    }
    print('--- DEBUG DATA END ---');
  });
}
