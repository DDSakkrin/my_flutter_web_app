import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logging/logging.dart';

class ImageService {
  static final Logger _logger = Logger('ImageService');

  static Future<String> uploadImageFromBytes(Uint8List imageBytes) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('event_images/${DateTime.now().toIso8601String()}.png');
      final uploadTask = storageRef.putData(imageBytes);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logger.severe('Error uploading image from bytes: $e');
      throw Exception('Error uploading image');
    }
  }

  static Future<String> uploadImageFromFile(File imageFile) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('event_images/${DateTime.now().toIso8601String()}.png');
      final uploadTask = storageRef.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      _logger.severe('Error uploading image from file: $e');
      throw Exception('Error uploading image');
    }
  }

  static Future<void> deleteImage(String imageUrl) async {
    try {
      await FirebaseStorage.instance.refFromURL(imageUrl).delete();
      _logger.info('Image deleted: $imageUrl');
    } catch (e) {
      _logger.severe('Error deleting image: $e');
      throw Exception('Error deleting image');
    }
  }
}
