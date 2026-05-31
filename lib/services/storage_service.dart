import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../constants/app_constants.dart';
import 'package:flutter/material.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Upload Avatar
  Future<String?> uploadAvatar({
    required String userId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('avatars/$userId/avatar.jpg');
      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Upload Chat Image
  Future<String?> uploadChatImage({
    required String chatId,
    required File imageFile,
  }) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('chats/$chatId/images/$fileName');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Upload Community Icon
  Future<String?> uploadCommunityIcon({
    required String communityId,
    required File imageFile,
  }) async {
    try {
      final ref = _storage.ref().child('communities/$communityId/icon.jpg');
      final uploadTask = await ref.putFile(imageFile);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  // Pick Image from Gallery
  Future<File?> pickImageFromGallery({bool crop = true}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return null;

    if (crop) {
      return await _cropImage(picked.path);
    }
    return File(picked.path);
  }

  // Pick Image from Camera
  Future<File?> pickImageFromCamera({bool crop = true}) async {
    final picked = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (picked == null) return null;

    if (crop) {
      return await _cropImage(picked.path);
    }
    return File(picked.path);
  }

  // Crop Image
  Future<File?> _cropImage(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: AppColors.bgDark,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: true,
          backgroundColor: AppColors.bgDark,
          activeControlsWidgetColor: AppColors.primary,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: true,
          minimumAspectRatio: 1.0,
        ),
      ],
    );
    if (cropped == null) return null;
    return File(cropped.path);
  }

  // Delete File
  Future<void> deleteFile(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (_) {}
  }
}
