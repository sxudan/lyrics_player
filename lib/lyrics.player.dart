import 'package:better_player/better_player.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LyricsPlayer extends StatefulWidget {
  const LyricsPlayer({required this.url, super.key});

  final String url;

  @override
  State<LyricsPlayer> createState() => _LyricsPlayerState();
}

class _LyricsPlayerState extends State<LyricsPlayer> {
  late BetterPlayerController _betterPlayerController;
  GlobalKey _betterPlayerKey = GlobalKey();
  double progress = 0;
  int currentTimestamp = 0;
  int duration = 0;

  @override
  void initState() {
    BetterPlayerConfiguration betterPlayerConfiguration =
        const BetterPlayerConfiguration(
            controlsConfiguration: BetterPlayerControlsConfiguration(
                showControls: true,
                controlBarColor: Colors.transparent,
                backgroundColor: Colors.transparent),
            fit: BoxFit.contain,
            deviceOrientationsOnFullScreen: [DeviceOrientation.portraitUp]);
    _betterPlayerController = BetterPlayerController(betterPlayerConfiguration);

    _betterPlayerController.addEventsListener((event) {
      final tmp = _betterPlayerController
              .videoPlayerController?.value.position.inMilliseconds ??
          0;
      if (tmp > duration) {
        return;
      }
      currentTimestamp = tmp;

      setState(() {});
    });

    _betterPlayerController.setBetterPlayerGlobalKey(_betterPlayerKey);
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) async {
      _betterPlayerController.setOverriddenAspectRatio(
          MediaQuery.of(context).size.width /
              MediaQuery.of(context).size.height);
      initialiseVideo(widget.url);
      setState(() {});
    });

    super.initState();
  }

  void initialiseVideo(String url) async {
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      url,
    );
    await _betterPlayerController.setupDataSource(dataSource);
    duration = _betterPlayerController
            .videoPlayerController?.value.duration?.inMilliseconds ??
        0;
    _betterPlayerController.play();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: buildPlayer(),
      ),
    );
  }

  Widget buildPlayer() {
    return Column(
      children: [
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: BetterPlayer(
              controller: _betterPlayerController,
              key: _betterPlayerKey,
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: () {
                _betterPlayerController
                    .enablePictureInPicture(_betterPlayerKey);
                _betterPlayerController.play();
              },
              child: Text('Enable PIP'),
            ),
            TextButton(
              onPressed: () {
                _betterPlayerController.setControlsVisibility(true);
                setState(() {});
              },
              child: Text('Enable Fullscreen'),
            ),
          ],
        ),
        Slider(
            value: currentTimestamp.toDouble(),
            min: 0,
            max: duration.toDouble(),
            onChanged: (value) async {
              await _betterPlayerController
                  .seekTo(Duration(milliseconds: value.toInt()));
            }),
        Row(
          children: [
            const SizedBox(
              width: 16,
            ),
            Text(DateFormat('mm:ss.SSS').format(
                DateTime.fromMillisecondsSinceEpoch(currentTimestamp).toUtc())),
            Expanded(child: SizedBox()),
            Text(DateFormat('mm:ss.SSS')
                .format(DateTime.fromMillisecondsSinceEpoch(duration).toUtc())),
            const SizedBox(
              width: 16,
            ),
          ],
        ),
        SizedBox(
          height: 24,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  if (_betterPlayerController
                          .videoPlayerController?.value.isPlaying ??
                      false) {
                    _betterPlayerController.pause();
                  } else {
                    _betterPlayerController.play();
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(60),
                  ),
                  child: Icon(
                    _betterPlayerController
                                .videoPlayerController?.value.isPlaying ??
                            false
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ))
          ],
        )
      ],
    );
  }
}
