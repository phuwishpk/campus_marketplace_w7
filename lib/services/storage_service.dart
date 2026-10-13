import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage;

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  Future<String> uploadListingImage(File imageFile, String sellerId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = 'listings/${sellerId}_$timestamp.jpg';
    final ref = _storage.ref().child(path);
    final uploadTask = await ref.putFile(imageFile);
    final downloadUrl = await uploadTask.ref.getDownloadURL();
    return downloadUrl;
  }
}
