import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_camera/flutter_camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'video_player.dart';
import 'dart:convert';

class CameraPage extends StatefulWidget {
  const CameraPage({Key? key, required this.onUploadProgress})
      : super(key: key);

  final Function(bool) onUploadProgress;

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
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
        'https://2785-2401-4900-632c-9581-2d1a-17c9-be48-e967.ngrok-free.app/generate_combined_video?text=hi&video_path=D:/final/final_app/app/asset/sample_video.mp4';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Video path sent to backend successfully');
        print('Response from backend: ${response.body}');

        if (response.body.contains('"combined_video_path"')) {
          final Map<String, dynamic> responseBody = json.decode(response.body);

          if (responseBody.containsKey('message')) {
            final extractedText = responseBody['message'];
            navigatorKey.currentState?.push(
              MaterialPageRoute(
                builder: (context) =>
                    VideoPlayerScreen(subtitle: extractedText),
              ),
            );
          }
        }
        // You can handle the response from the backend here
      } else {
        print(
            'Failed to send video path to backend. Status code: ${response.statusCode}');
      }
    } finally {
      widget.onUploadProgress(false);
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
        final videoPath = value.path;
        print('Video Path: $videoPath');

        // Upload the recorded video to Firebase
        await uploadVideoToFirebase(videoPath);
      },
    );
  }
}
