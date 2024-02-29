import 'package:app/sign_talk_camera.dart';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;

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
  late VideoPlayerController _controller1;
  late Future<void> _initializeVideoPlayerFuture1;

  final TextEditingController _textcontroller = TextEditingController();
  late stt.SpeechToText _speech;
  bool _isListening = false;

  void _sendMessage(String text) async {
    text2sign = text;
    _textcontroller.clear();
    final url =
        'https://6338-2409-408d-782-717-19a5-6f77-95e4-866.ngrok-free.app/sign?text=$text2sign';

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
            _initVideoController1();
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

  void _initVideoController1() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        "https://firebasestorage.googleapis.com/v0/b/htmlapp-fa3bc.appspot.com/o/video.mp4?alt=media&token=e2aeeffe-e2ad-4640-8f2b-a3ca60abfbbb"));
    _initializeVideoPlayerFuture = _controller.initialize();
    initializeVideoPlayerFuture.then(() {
      setState(() {});
    });
  }

  void _initVideoController2() {
    _controller1 = VideoPlayerController.networkUrl(Uri.parse(
        "https://firebasestorage.googleapis.com/v0/b/sign-app-d3980.appspot.com/o/videos%2Fsample.mp4?alt=media&token=03ea3cc5-17cd-466f-a4e0-366ac3ee318e"));
    _initializeVideoPlayerFuture1 = _controller1.initialize();
    initializeVideoPlayerFuture.then(() {
      setState(() {});
    });
  }

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initVideoController1();
    _initVideoController2();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller1.dispose();
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
              Container(
                height: 250,
                width: 250,
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(
                          _controller,
                          key: UniqueKey(),
                        ),
                      );
                    } else {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                  },
                ),
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
    _initVideoController2();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              height: 250,
              width: 250,
              child: FutureBuilder(
                future: _initializeVideoPlayerFuture1,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(
                        _controller1,
                        key: UniqueKey(),
                      ),
                    );
                  } else {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            ),
          ),
          // Add FloatingActionButton for video playback control
          const SizedBox(
            height: 10,
          ),
          Center(
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  if (_controller.value.isPlaying) {
                    _controller1.pause();
                  } else {
                    _controller1.play();
                  }
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),

          const SizedBox(
            height: 8,
          ),
          Center(
            child: Text(
              sign2text,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(
            width: 5,
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

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              text2sign = val.recognizedWords;
            });
          },
        );
      }
    } else {
      setState(() {
        _isListening = false;
        _speech.stop();
        _sendMessage(text2sign);
      });

      // _sendMessage(text2sign);
      // Call sendMessage() after stopping speech recognition
    }
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
                          onSubmitted: (_) =>
                              _sendMessage(_textcontroller.text),
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
                        onPressed: () {
                          _sendMessage(_textcontroller.text);
                        },
                        icon: const Icon(Icons.send),
                      ),
                      const SizedBox(
                        width: 6,
                      ),
                      IconButton(
                        onPressed: _listen,
                        icon: Icon(_isListening ? Icons.upload : Icons.mic),
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