import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:io';
import 'package:ffmpeg_kit_flutter_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full/return_code.dart';
import 'package:flutter/services.dart';
import 'package:lyrics_player/srt.dart';
import 'package:lyrics_player/lyrics.player.dart';
import 'package:path_provider/path_provider.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  double progress = 0;
  int duration = 0;
  List<String> assets = ['heavy.srt', 'it_aint_me.srt', 'let_me_love_you.srt'];

  Future<String> getPath(String name) async {
    /// initialize output path
    Directory dir = await getTemporaryDirectory();
    File output = File('${dir.path}/$name');
    return output.path;
  }

  late SRT srt;

  @override
  void initState() {
    super.initState();
  }

  Future<String> generate(String name) async {
    final completer = Completer<String>();
    String outputPath = await getPath('output.mp4');
    if (File(outputPath).existsSync()) {
      File(outputPath).deleteSync();
    }
    String? assetPath = await _copyAssetToLocal(name);
    if (assetPath == null) {
      print('Subtitle is null');
      completer.completeError('No subtitle');
    } else {
      srt = SRT(assetPath);
      await srt.initialise();
      setState(() {
        duration = (srt.getDuration() * 1000).toInt();
      });
      String cmd =
          '-f lavfi -i color=c=0x0E1D9D:s=360x640:d=${srt.getDuration()} -filter_complex "subtitles=$assetPath:force_style=\'Alignment=10,Fontsize=24,MarginV=14,MarginL=24,MarginR=24,Outline=0,Shadow=0.5\'" -vcodec h264 $outputPath';
      FFmpegKit.executeAsync(cmd, (session) async {
        print(session.getCommand());
        final code = await session.getReturnCode();
        if (ReturnCode.isSuccess(code)) {
          if (File(outputPath).existsSync()) {
            // generateSubtitle();
            print('SUCCESS');
            completer.complete(outputPath);
          } else {
            completer.completeError('File doesnot exist');
          }
        } else {
          print('Error');
          completer.completeError('Error');
        }
        setState(() {
          progress = 0;
          duration = 0;
        });
      }, (log) {
        // print(log.getMessage());
      }, (stats) {
        if (stats.getTime() > 0) {
          // double totalProgress = (stats.getTime()) / srt.getDuration() * 1000;
          setState(() {
            progress = stats.getTime();
          });
        }
      });
    }

    return completer.future;
  }

  Future<String?> _copyAssetToLocal(String name) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      var file = File("${directory.path}/${name}");
      if (file.existsSync()) {
        file.deleteSync();
      }
      var content = await rootBundle.load("assets/$name");
      file.writeAsBytesSync(content.buffer.asUint8List());
      return file.path;
    } catch (e) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lyrics'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListView.separated(
                shrinkWrap: true,
                separatorBuilder: (context, index) => const Divider(
                  thickness: 1,
                ),
                itemCount: assets.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    onTap: () async {
                      final outputPath = await generate(assets[index]);
                      // ignore: use_build_context_synchronously
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => LyricsPlayer(url: outputPath),
                          ));
                    },
                    title: Text(assets[index]),
                  );
                },
              ),
              const SizedBox(
                height: 16,
              ),
              Text('$progress / $duration')
            ],
          ),
        ),
      ),
    );
  }
}
