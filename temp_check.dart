import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // We can't easily initialize Firebase without the app setup in a plain script
  // if it's not a flutter test or using admin sdk.
  print('done');
}
