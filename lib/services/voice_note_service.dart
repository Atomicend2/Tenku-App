// ============================================================
// VOICE NOTE SERVICE
// Uses flutter_sound for recording and playback.
// Add to pubspec.yaml:
//   flutter_sound: ^9.2.13
//   permission_handler: ^11.3.1  (already included)
// ============================================================

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../models/phase3_models.dart';

class VoiceNoteService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Upload recorded voice note ──────────────────────────
  Future<VoiceNoteModel> uploadAndSend({
    required String chatId,
    required String senderId,
    required String senderName,
    required String localPath,
    required int durationSeconds,
    required List<double> waveform,
    bool isChannelMessage = false,
  }) async {
    final file = File(localPath);
    final fileName = 'voice_${DateTime.now().millisecondsSinceEpoch}.aac';
    final storageRef = _storage.ref().child('voice_notes/$chatId/$fileName');

    final uploadTask = await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'audio/aac'),
    );
    final audioUrl = await uploadTask.ref.getDownloadURL();

    final id = DateTime.now().millisecondsSinceEpoch.toString();

    final voiceNote = VoiceNoteModel(
      id: id,
      senderId: senderId,
      senderName: senderName,
      audioUrl: audioUrl,
      durationSeconds: durationSeconds,
      createdAt: DateTime.now(),
      waveform: waveform,
    );

    // Save as message
    final collection = isChannelMessage
        ? _db.collection('channels').doc(chatId).collection('messages')
        : _db.collection('chats').doc(chatId).collection('messages');

    await collection.add({
      'chatId': chatId,
      'senderId': senderId,
      'senderName': senderName,
      'content': '🎤 Voice message',
      'type': 'audio',
      'status': 'sent',
      'createdAt': FieldValue.serverTimestamp(),
      'isDeleted': false,
      'reactions': [],
      'mediaUrl': audioUrl,
      'fileName': fileName,
      'fileSize': await file.length(),
      'voiceNote': voiceNote.toMap(),
    });

    return voiceNote;
  }

  // ─── Generate fake waveform for demo (replace with real) ─
  static List<double> generateDemoWaveform(int samples) {
    final rng = Random();
    return List.generate(samples, (i) {
      final base = sin(i * 0.3) * 0.3 + 0.4;
      return (base + rng.nextDouble() * 0.3).clamp(0.1, 1.0);
    });
  }

  Future<String> getLocalRecordingPath() async {
    final dir = await getTemporaryDirectory();
    return '${dir.path}/tenku_voice_${DateTime.now().millisecondsSinceEpoch}.aac';
  }
}
