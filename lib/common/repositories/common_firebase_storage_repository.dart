import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final commonFirebaseRepositoryProvider = Provider((ref)=> CommonFirebaseStorageRepository(firebaseStorage: FirebaseStorage.instance));

class CommonFirebaseStorageRepository{
  final FirebaseStorage firebaseStorage;
  CommonFirebaseStorageRepository({required this.firebaseStorage});

  Future<String> storeFileToFirebase(String ref, File file) async {
    try {
      final storageRef = firebaseStorage.ref().child(ref);
      final uploadTask = storageRef.putFile(file);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Storage error: $e');
      rethrow;
    }
  }

}