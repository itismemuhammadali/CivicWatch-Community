import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'core/firebase/firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  print('--- DEBUG DATA START ---');
  try {
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
}
