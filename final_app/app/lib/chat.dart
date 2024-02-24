import 'package:app/chatbot_camera.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class ChatBot extends StatefulWidget {
  const ChatBot({Key? key}) : super(key: key);

  @override
  State<ChatBot> createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  bool responseLoader = false;

  bool user1 = false;
  bool gemini1 = false;
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;
  late VideoPlayerController _controller2;
  late Future<void> _initializeVideoPlayerFuture2;

  @override
  void initState() {
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        "https://firebasestorage.googleapis.com/v0/b/sign-app-d3980.appspot.com/o/videos%2Fsample.mp4?alt=media&token=03ea3cc5-17cd-466f-a4e0-366ac3ee318e"))
      ..setLooping(true);
    _initializeVideoPlayerFuture = _controller.initialize();
    initializeVideoPlayerFuture.then(() {
      setState(() {
        _controller.play();
      });
    });

    // Initialize the second video player
    _controller2 = VideoPlayerController.networkUrl(Uri.parse(
        'https://firebasestorage.googleapis.com/v0/b/htmlapp-fa3bc.appspot.com/o/video.mp4?alt=media&token=d294509c-66ae-4206-a352-271b769b288e'))
      ..setLooping(true);
    _initializeVideoPlayerFuture2 = _controller2.initialize();
    initializeVideoPlayerFuture2.then(() {
      setState(() {
        _controller2.play();
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller2.dispose();
    super.dispose();
  }

  Widget user() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: Container(
            height: 35,
            width: 35,
            decoration: const BoxDecoration(
              image:
                  DecorationImage(image: AssetImage('asset/images/user.png')),
            ),
          ),
        ),
        Expanded(
          child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        width: 200,
                        height: 250,
                        child: VideoPlayer(_controller),
                      );
                    } else {
                      return const Center(
                          child:
                              CircularProgressIndicator()); // Show loading indicator
                    }
                  },
                ),
              )),
        ),
      ],
    );
  }

  Widget gemini() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, top: 8, bottom: 8),
          child: Container(
            height: 35,
            width: 35,
            decoration: const BoxDecoration(
              image:
                  DecorationImage(image: AssetImage('asset/images/gemini.png')),
            ),
          ),
        ),
        Expanded(
          child: Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: FutureBuilder(
                  future: _initializeVideoPlayerFuture2,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Container(
                        width: 200,
                        height: 250,
                        child: VideoPlayer(_controller2),
                      );
                    } else {
                      return const Center(
                          child:
                              CircularProgressIndicator()); // Show loading indicator
                    }
                  },
                ),
              )),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: GestureDetector(
              child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatCamera(
                          user: (bool user) {
                            setState(() {
                              user1 = user;
                            });
                          },
                          gemini: (bool gemini) {
                            setState(() {
                              gemini1 = gemini;
                            });
                          },
                          onUploadProgress: (bool progress) {
                            setState(() {
                              responseLoader = progress;
                            });
                          },
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.camera_alt_rounded)),
            ),
          )
        ],
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu)),
        backgroundColor: Colors.grey.withOpacity(0.3),
        title: const Text(
          'SignBot',
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
                    child: ListView.builder(
                  itemBuilder: (context, index) {
                    if (user1 && index.isEven) {
                      return user();
                    } else if (gemini1 && index.isOdd) {
                      return gemini();
                    } else {
                      return Container(); // Return an empty container if neither condition is met
                    }
                  },
                  itemCount:
                      2, // Adjust the itemCount to the actual number of items you want to display
                )),
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