import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_camera/flutter_camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'video_player.dart';
import 'dart:convert';

class ChatCamera extends StatefulWidget {
  const ChatCamera(
      {Key? key,
      required this.onUploadProgress,
      required this.user,
      required this.gemini})
      : super(key: key);

  final Function(bool) onUploadProgress;
  final Function(bool) user;
  final Function(bool) gemini;

  @override
  _ChatCameraState createState() => _ChatCameraState();
}

class _ChatCameraState extends State<ChatCamera> {
  Future<void> uploadVideoToFirebase(String videoPath) async {
    try {
      widget.onUploadProgress(true);
      final file = File(videoPath);
      const fileName = "videos/sample.mp4";

      final ref = FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = ref.putFile(file);

      // Track the upload progress
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        double progress =
            (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('Upload progress: $progress%');
      });

      // Wait for the upload to complete
      await uploadTask.whenComplete(() {
        widget.user(true);
        print('Upload complete');
        sendVideoPathToBackend();

        // You can perform any additional actions after the upload is complete
      });
    } catch (e) {
      // Handle errors during the upload
      print('Error uploading video: $e');
    }
  }

  Future<void> sendVideoPathToBackend() async {
    const url =
        'https://1e84-2409-408d-1d82-500c-d1ae-955b-5a76-591f.ngrok-free.app/bot?video_path=D:/final/final_app/python/sample_video.mp4';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Video path sent to backend successfully');
        print('Response from backend: ${response.body}');

        if (response.body.contains('"message"')) {
          widget.onUploadProgress(false);
          widget.gemini(true);
        }
        // You can handle the response from the backend here
      } else {
        print(
            'Failed to send video path to backend. Status code: ${response.statusCode}');
      }
    } finally {
      //widget.onUploadProgress(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FlutterCamera(
      color: Colors.amber,
      onImageCaptured: (value) {
        final imagePath = value.path;
        print("Image Path: $imagePath");

        // Your logic for handling images
      },
      onVideoRecorded: (value) async {
        widget.onUploadProgress(true);
        final videoPath = value.path;
        print('Video Path: $videoPath');

        // Upload the recorded video to Firebase
        await uploadVideoToFirebase(videoPath);
      },
    );
  }
}
