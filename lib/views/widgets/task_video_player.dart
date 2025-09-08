import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class TaskVideoPlayer extends StatefulWidget {
  const TaskVideoPlayer({required this.videoUrl, super.key});
  final String videoUrl;

  @override
  State<TaskVideoPlayer> createState() => _TaskVideoPlayerState();
}

class _TaskVideoPlayerState extends State<TaskVideoPlayer> {
  late final VideoPlayerController _controller;
  bool _ready = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..setLooping(false)
      ..initialize()
          .then((_) {
            if (!mounted) return;
            setState(() => _ready = true);
          })
          .catchError((e) {
            if (!mounted) return;
            setState(() => _error = 'Unable to load video');
          });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Text(_error!, style: const TextStyle(color: Colors.red));
    }

    if (!_ready) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    final aspect = _controller.value.aspectRatio == 0
        ? 16 / 9
        : _controller.value.aspectRatio;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: aspect,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_controller),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _controller.value.isPlaying
                        ? _controller.pause()
                        : _controller.play();
                  });
                },
                child: Container(
                  color: Colors.black26,
                  child: Icon(
                    _controller.value.isPlaying
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                    color: Colors.white,
                    size: 64,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        VideoProgressIndicator(
          _controller,
          allowScrubbing: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    );
  }
}
