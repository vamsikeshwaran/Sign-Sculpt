import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String subtitle;

  const VideoPlayerScreen({Key? key, required this.subtitle}) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  late ChewieController _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(
        "https://firebasestorage.googleapis.com/v0/b/newfinalvideo.appspot.com/o/video.mp4?alt=media&token=3c06b49b-fda4-4ad3-a198-88093419542b"));
    _chewieController = ChewieController(
      videoPlayerController: _controller,
      autoPlay: true,
      looping: true,
      aspectRatio: 16 / 9,
    );

    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() async {
    await _controller.initialize();
    setState(() {}); // Update the UI once the video is initialized
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController.dispose();
    super.dispose();
  }

  Future<void> _downloadVideo() async {
    try {
      final taskId = await FileDownloader.downloadFile(
          url:
              'https://firebasestorage.googleapis.com/v0/b/newfinalvideo.appspot.com/o/video.mp4?alt=media&token=68485517-5866-4383-9c94-4bf92830a494',
          onDownloadCompleted: (String path) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File downloaded successfully!'),
              ),
            );
          });
    } catch (error) {
      print('Error downloading video: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _downloadVideo,
          ),
        ],
      ),
      body: Stack(
        children: [
          Center(
            child: _chewieController != null &&
                    _chewieController.videoPlayerController.value.isInitialized
                ? Chewie(
                    controller: _chewieController,
                  )
                : const CircularProgressIndicator(),
          ),
          if (_controller.value.isInitialized)
            Positioned(
              bottom: 0.0,
              left: 0.0,
              right: 0.0,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 180),
                  child: Container(
                    color: Colors.black.withOpacity(
                        0.5), // Add some background color for better visibility
                    padding: const EdgeInsets.all(5),
                    child: Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
