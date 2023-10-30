import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

import 'package:video_player/video_player.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MainBody(),
    );
  }
}

class MainBody extends StatefulWidget {
  const MainBody({
    super.key,
  });

  @override
  State<MainBody> createState() => _MainBodyState();
}

class _MainBodyState extends State<MainBody> {
  final link =
      "https://media.kanjialive.com/kanji_animations/kanji_mp4/otozu(reru)_00.mp4";
  late File myFile;
  String fileText = '';
  String path = '';
  VideoPlayerController? _controller;
  late Directory dir;
  String fileName = '';

  Future<bool> writeFile() async {
    try {
      await myFile.writeAsString('Margherita, Capricciosa, Napoli');
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> initialSetup() async {
    dir = await getApplicationDocumentsDirectory();
    fileName = 'myFile.mp4';
  }

  @override
  void initState() {
    super.initState();
    initialSetup();
  }

  Future<bool> download({required String url}) async {
    // requests permission for downloading the file
    bool hasPermission = await _requestWritePermission();
    if (!hasPermission) return false;

    // gets the directory where we will download the file.

    // downloads the file
    Dio dio = Dio();
    final response = await dio.download(
      url,
      "${dir.path}/$fileName",
      onReceiveProgress: (received, total) {
        if (total != -1) {
          print((received / total * 100).toStringAsFixed(0) + "%");
          //you can build progressbar feature too
        }
      },
    );

    return response.statusCode != null && response.statusCode! < 400;

/*     final myFile2 = File("${dir.path}/$fileName");
    String fileContent = await myFile2.readAsString();
    setState(() {
      fileText = fileContent;
    }); */
    // opens the file
    //OpenFile.open("${dir.path}/$fileName", type: 'application/pdf');
  }

// requests storage permission

  @override
  void dispose() {
    super.dispose();
    _controller?.dispose();
  }

  Future<bool> _requestWritePermission() async {
    await Permission.storage.request();
    return await Permission.storage.request().isGranted;
  }

  Future<bool> readFile() async {
    try {
// Read the file.
      String fileContent = await myFile.readAsString();
      setState(() {
        fileText = fileContent;
      });
      return true;
    } catch (e) {
// On error, return false.
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        body: Center(
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                path,
                textAlign: TextAlign.center,
              ),
              Text(
                fileText,
                textAlign: TextAlign.center,
              ),
              _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : Container(
                      width: 256,
                      height: 256,
                      color: Colors.amberAccent,
                    ),
              ElevatedButton(
                child: const Text('download video'),
                onPressed: () {
                  download(url: link).then((value) {
                    if (!value) return;
                    _controller = VideoPlayerController.file(
                        File("${dir.path}/$fileName"))
                      ..initialize().then((_) {
                        setState(() {});
                      });
                  });
                },
              ),
              ElevatedButton(
                child: const Text(
                  'write file',
                  textAlign: TextAlign.center,
                ),
                onPressed: () {
                  getApplicationDocumentsDirectory().then((value) {
                    setState(() {
                      path = value.path;
                    });
                    myFile = File('${value.path}/pizzas.txt');
                    writeFile();
                  });
                },
              ),
              ElevatedButton(
                  onPressed: () {
                    readFile().then((value) {});
                  },
                  child: const Text('Read file'))
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _controller == null
              ? null
              : () {
                  setState(() {
                    _controller == null && _controller!.value.isPlaying
                        ? _controller!.pause()
                        : _controller!.play();
                  });
                },
          child: Icon(decideIcon()),
        ));
  }

  IconData decideIcon() {
    if (_controller == null) {
      return Icons.error;
    } else if (_controller == null && _controller!.value.isPlaying) {
      return Icons.pause;
    } else if (_controller == null && !_controller!.value.isPlaying) {
      return Icons.play_arrow;
    } else {
      return Icons.question_mark;
    }
  }
}
