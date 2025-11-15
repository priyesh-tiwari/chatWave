import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerItem extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerItem({super.key , required this.videoUrl});


  @override
  State<VideoPlayerItem> createState() => _VideoPlayerItemState();
}

class _VideoPlayerItemState extends State<VideoPlayerItem> {
  bool isPlay=false;


  late VideoPlayerController videoPlayerController;
  
  @override

  void initState(){
    super.initState();
    videoPlayerController=VideoPlayerController.network(widget.videoUrl)..initialize().then((value){
      videoPlayerController.setVolume(1);
    });
  }

  void dispose(){
    super.dispose();
    videoPlayerController.dispose();
  }
  Widget build(BuildContext context) {
    return  AspectRatio(
        aspectRatio: 16/9,
      child: Stack(
        children: [
          VideoPlayer(videoPlayerController),
          Align(
            alignment: Alignment.center,
            child: IconButton(
                onPressed: (){
                  if(isPlay){
                    videoPlayerController.pause();
                  }else{
                    videoPlayerController.play();
                  }
                  setState(() {
                    isPlay=!isPlay;
                  });
                },
                icon: Icon(isPlay?Icons.pause_circle:Icons.play_circle)
            ),
          )
        ],
      ),
    );
  }
}
