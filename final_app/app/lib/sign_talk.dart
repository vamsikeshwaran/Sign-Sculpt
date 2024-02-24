import 'package:app/chatbot_camera.dart';
import 'package:app/sign_talk_camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

enum DisplayMode { none, textToSign, signToText }

DisplayMode displayMode = DisplayMode.none;

class SignTalk extends StatefulWidget {
  const SignTalk({Key? key}) : super(key: key);

  @override
  State<SignTalk> createState() => _ChatBotState();
}

class _ChatBotState extends State<SignTalk> {
  var text2sign = '';
  var sign2text = '';
  bool responseLoader = false;
  bool isLoading = false;
  bool videoPlayer = false;
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  final TextEditingController _textcontroller = TextEditingController();

  void _sendMessage() async {
    text2sign = _textcontroller.text;
    _textcontroller.clear();
    final url =
        'https://5980-2409-40f4-17-349e-c4bc-a78-2da2-d840.ngrok-free.app/sign?text=$text2sign';

    setState(() {
      responseLoader = true;
    });

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        print('Video path sent to backend successfully');
        print('Response from backend: ${response.body}');

        if (response.body.contains('"message"')) {
          setState(() {
            displayMode = DisplayMode.textToSign;
          });
        }
        // You can handle the response from the backend here
      } else {
        print(
            'Failed to send video path to backend. Status code: ${response.statusCode}');
      }
    } finally {
      setState(() {
        responseLoader = false;
      });
    }
  }

  @override
  void initState() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        "https://firebasestorage.googleapis.com/v0/b/htmlapp-fa3bc.appspot.com/o/video.mp4?alt=media&token=e2aeeffe-e2ad-4640-8f2b-a3ca60abfbbb"));
    _initializeVideoPlayerFuture = _controller.initialize();

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget textToSign() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Text(
            text2sign,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              FutureBuilder(
                future: _initializeVideoPlayerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
              // Add FloatingActionButton for video playback control
              const SizedBox(
                height: 10,
              ),
              FloatingActionButton(
                onPressed: () {
                  setState(() {
                    if (_controller.value.isPlaying) {
                      _controller.pause();
                    } else {
                      _controller.play();
                    }
                  });
                },
                child: Icon(
                  _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget signToText() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Generated Text",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
          const SizedBox(
            height: 8,
          ),
          Row(
            children: [
              Text(
                sign2text,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(
                width: 5,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void updateDisplayMode() {
    setState(() {
      displayMode = DisplayMode.signToText;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (videoPlayer) {
      updateDisplayMode(); // Call updateDisplayMode() to update the state
    }
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        backgroundColor: Colors.grey.withOpacity(0.3),
        title: const Text(
          'SignTalk',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            child: Column(
              children: [
                Expanded(
                    child: ListView(
                  children: [
                    if (displayMode == DisplayMode.textToSign) textToSign(),
                    if (displayMode == DisplayMode.signToText) signToText(),
                  ],
                )),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  margin: const EdgeInsets.only(
                      bottom: 40, right: 16, left: 16, top: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _textcontroller,
                          onSubmitted: (_) => _sendMessage(),
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            hintText: "Say anything...",
                            border:
                                OutlineInputBorder(borderSide: BorderSide.none),
                            filled: false,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _sendMessage,
                        icon: const Icon(Icons.send),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.mic),
                      ),
                      const SizedBox(
                        width: 10,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 5),
                        child: IconButton(
                          onPressed: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => SignTalkCamera(
                                            onUploadProgress:
                                                (bool isProgress) {
                                          setState(() {
                                            isLoading = isProgress;
                                          });
                                        }, onResponseReceived:
                                                (String responseText) {
                                          setState(() {
                                            sign2text =
                                                responseText; // Store the response text
                                            videoPlayer = true;
                                          });
                                        }, responseLoader: (bool res) {
                                          setState(() {
                                            responseLoader = res;
                                          });
                                        })));
                          },
                          icon: const Icon(Icons.camera_alt_outlined),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (responseLoader)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}