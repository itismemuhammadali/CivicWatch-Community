import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cctv_app/core/network/models/uploaded_media.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class ApplicationCloudService {
  const ApplicationCloudService();

  Future<UploadedMedia> uploadImage({
    required String accessToken,
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    return _uploadFile(
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      folder: 'images',
    );
  }

  Future<UploadedMedia> uploadVideo({
    required String accessToken,
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
  }) async {
    return _uploadFile(
      filePath: filePath,
      fileBytes: fileBytes,
      fileName: fileName,
      folder: 'videos',
    );
  }

  Future<UploadedMedia> _uploadFile({
    required String filePath,
    Uint8List? fileBytes,
    String? fileName,
    required String folder,
  }) async {
    final resolvedFileName = fileName ?? filePath.split(RegExp(r'[\\/]')).last;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '$folder/${timestamp}_$resolvedFileName';
    
    final ref = FirebaseStorage.instance.ref().child(path);
    
    if (kIsWeb && fileBytes != null) {
      await ref.putData(fileBytes);
    } else {
      await ref.putFile(File(filePath));
    }
    
    final downloadUrl = await ref.getDownloadURL();
    final metaId = timestamp;
    final metaTypeId = folder == 'images' ? 1 : 2;

    // Save metadata to Firestore
    try {
      await FirebaseFirestore.instance.collection('media').doc('$metaId').set({
        'meta_id': metaId,
        'meta_url': downloadUrl,
        'meta_type_id': metaTypeId,
        'is_active': 'Y',
      });
    } catch (_) {}
    
    return UploadedMedia(
      metaId: metaId,
      metaUrl: downloadUrl,
      metaTypeId: metaTypeId,
    );
  }
}
