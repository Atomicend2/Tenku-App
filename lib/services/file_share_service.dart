import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import '../models/message_model.dart';
import '../constants/app_constants.dart';
import 'chat_service.dart';

class FileShareService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ChatService _chatService = ChatService();

  static const List<String> allowedExtensions = [
    'pdf', 'docx', 'doc', 'xlsx', 'xls', 'pptx', 'ppt',
    'zip', 'rar', 'tar', 'gz',
    'jpg', 'jpeg', 'png', 'gif', 'webp',
    'mp4', 'mov', 'avi', 'mkv',
    'mp3', 'wav', 'ogg',
    'txt', 'md',
  ];

  static const int maxFileSizeMB = 25;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  Future<void> pickAndSendFile({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    Function(double)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final filePath = picked.path;
    if (filePath == null) return;

    final file = File(filePath);
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) throw Exception('File too large. Max ${maxFileSizeMB}MB.');

    final fileName = picked.name;
    final ext = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    final type = _getMessageType(ext);

    final storageRef = _storage.ref().child('chat_files/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final uploadTask = storageRef.putFile(file, SettableMetadata(contentType: _getContentType(ext)));

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snap) => onProgress(snap.bytesTransferred / snap.totalBytes));
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: fileName,
      type: type,
      mediaUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  Future<void> sendImageFromGallery({
    required String chatId,
    required String senderId,
    required String senderName,
    String? senderAvatar,
    Function(double)? onProgress,
  }) async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result == null || result.files.isEmpty) return;
    final picked = result.files.first;
    final filePath = picked.path;
    if (filePath == null) return;

    final file = File(filePath);
    final fileSize = await file.length();
    if (fileSize > maxFileSizeBytes) throw Exception('Image too large.');

    final fileName = picked.name;
    final storageRef = _storage.ref().child('chat_images/$chatId/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final uploadTask = storageRef.putFile(file, SettableMetadata(contentType: 'image/jpeg'));

    if (onProgress != null) {
      uploadTask.snapshotEvents.listen((snap) => onProgress(snap.bytesTransferred / snap.totalBytes));
    }

    final snapshot = await uploadTask;
    final downloadUrl = await snapshot.ref.getDownloadURL();

    await _chatService.sendMessage(
      chatId: chatId,
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      content: fileName,
      type: MessageType.image,
      mediaUrl: downloadUrl,
      fileName: fileName,
      fileSize: fileSize,
    );
  }

  MessageType _getMessageType(String ext) {
    const imageExts = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
    const videoExts = ['mp4', 'mov', 'avi', 'mkv'];
    const audioExts = ['mp3', 'wav', 'ogg'];
    if (imageExts.contains(ext)) return MessageType.image;
    if (videoExts.contains(ext)) return MessageType.video;
    if (audioExts.contains(ext)) return MessageType.audio;
    return MessageType.file;
  }

  String _getContentType(String ext) {
    const types = {
      'pdf': 'application/pdf',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'doc': 'application/msword',
      'xlsx': 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'zip': 'application/zip',
      'jpg': 'image/jpeg', 'jpeg': 'image/jpeg', 'png': 'image/png', 'gif': 'image/gif',
      'mp4': 'video/mp4', 'mp3': 'audio/mpeg',
    };
    return types[ext] ?? 'application/octet-stream';
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static IconData getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file_rounded;
    final ext = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    const icons = <String, IconData>{
      'pdf': Icons.picture_as_pdf_rounded,
      'doc': Icons.description_rounded, 'docx': Icons.description_rounded,
      'xls': Icons.table_chart_rounded, 'xlsx': Icons.table_chart_rounded,
      'ppt': Icons.slideshow_rounded,   'pptx': Icons.slideshow_rounded,
      'zip': Icons.folder_zip_rounded,  'rar': Icons.folder_zip_rounded,
      'mp3': Icons.music_note_rounded,  'wav': Icons.music_note_rounded,
      'mp4': Icons.videocam_rounded,    'mov': Icons.videocam_rounded,
      'jpg': Icons.image_rounded,       'jpeg': Icons.image_rounded, 'png': Icons.image_rounded,
    };
    return icons[ext] ?? Icons.insert_drive_file_rounded;
  }

  static Color getFileColor(String? fileName) {
    if (fileName == null) return AppColors.textMuted;
    final ext = path.extension(fileName).toLowerCase().replaceFirst('.', '');
    const colors = <String, Color>{
      'pdf': Color(0xFFFF4466),
      'doc': Color(0xFF2B6CE6), 'docx': Color(0xFF2B6CE6),
      'xls': Color(0xFF00A550), 'xlsx': Color(0xFF00A550),
      'ppt': Color(0xFFFF6B35), 'pptx': Color(0xFFFF6B35),
      'zip': Color(0xFFFFB020), 'rar': Color(0xFFFFB020),
      'mp3': Color(0xFF9C63FF), 'wav': Color(0xFF9C63FF),
      'mp4': Color(0xFF00D4AA), 'mov': Color(0xFF00D4AA),
    };
    return colors[ext] ?? AppColors.primary;
  }
}
