import 'package:flutter/material.dart';
import 'package:tasks_flutter/strategy/video_url_strategy.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

class TaskYoutubePlayer extends StatefulWidget {
  const TaskYoutubePlayer({required this.url, super.key});
  final String url;

  @override
  State<TaskYoutubePlayer> createState() => _TaskYoutubePlayerState();
}

class _TaskYoutubePlayerState extends State<TaskYoutubePlayer> {
  YoutubePlayerController? _controller;

  @override
  void initState() {
    super.initState();
    final id = VideoUrlStrategy.instance.extractIdFor(
      widget.url,
      VideoPlatform.youtube,
    );

    if (id != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          strictRelatedVideos: true,
          enableJavaScript: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    if (c == null) {
      return const Text(
        'Invalid YouTube URL',
        style: TextStyle(color: Colors.red),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: YoutubePlayer(controller: c),
    );
  }
}
