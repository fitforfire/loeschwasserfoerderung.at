import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

// Root Widget for Video-Player Widget
class VideoPlayerWidget extends StatefulWidget {
  //Variable
  final String videoUrl;
  final double width;
  final double height;
  final double volume;

  //Constructor
  const VideoPlayerWidget({super.key, required this.videoUrl, required this.volume, required this.width, required this.height});

  //Create State
  @override
  State<VideoPlayerWidget> createState() => VideoPlayerWidgetState();
}

//State for the Widget
class VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  //Variables
  late final Player player;
  late final VideoController controller;

  //Initializer
  @override
  void initState() {
    super.initState();
    player = Player();
    controller = VideoController(player);
    player.open(Media(widget.videoUrl));
    player.setVolume(widget.volume);
  }

  //Disposer
  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  //Build the Widget
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.width,
          height: widget.height,
          child: Video(controller: controller),
        ),
      ],
    );
  }
}
