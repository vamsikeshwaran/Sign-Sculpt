import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_camera/flutter_camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'main.dart';
import 'video_player.dart';
import 'dart:convert';

class SignTalkCamera extends StatefulWidget {
  const SignTalkCamera(
      {Key? key,
      required this.onUploadProgress,
      required this.onResponseReceived,
      required this.responseLoader})
      : super(key: key);

  final Function(bool) onUploadProgress;
  final Function(String) onResponseReceived;
  final Function(bool) responseLoader;

  @override
  _ChatCameraState createState() => _ChatCameraState();
}

class _ChatCameraState extends State<SignTalkCamera> {
  Future<void> uploadVideoToFirebase(String videoPath) async {
    try {
      //widget.onUploadProgress(true);
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

  Future<String> sendVideoPathToBackend() async {
    const url =
        'https://f007-2409-408d-1d82-500c-c85b-962-c21-976f.ngrok-free.app/chat?video_path=/Users/vamsikeshwaran/Desktop/thanks.mp4';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        widget.responseLoader(false);
        print('Video path sent to backend successfully');
        print('Response from backend: ${response.body}');
        final decodedBody = json.decode(response.body);

        if (decodedBody.containsKey('message')) {
          final message = decodedBody['message'];
          widget.onUploadProgress(true);
          widget.onResponseReceived(message);
        }
      } else {
        print(
            'Failed to send video path to backend. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error sending video path to backend: $e');
    }

    return ''; // Return an empty string if there's an error or no valid response
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
        widget.responseLoader(true);
        final videoPath = value.path;
        print('Video Path: $videoPath');

        // Upload the recorded video to Firebase
        await uploadVideoToFirebase(videoPath);
      },
    );
  }
}
