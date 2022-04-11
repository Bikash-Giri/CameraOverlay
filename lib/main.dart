import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:cameraoverlay/display_picture_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

Future<void> main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Get a specific camera from the list of available cameras.
  final firstCamera = cameras.last;

  runApp(
    MaterialApp(
      theme: ThemeData.dark(),
      home: TakePictureScreen(
        // Pass the appropriate camera to the TakePictureScreen widget.
        camera: firstCamera,
      ),
    ),
  );
}

// A screen that allows users to take a picture using a given camera.
class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({
    Key? key,
    required this.camera,
  }) : super(key: key);

  final CameraDescription camera;

  @override
  TakePictureScreenState createState() => TakePictureScreenState();
}

class TakePictureScreenState extends State<TakePictureScreen> {
  late CameraController _controller;

  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    // To display the current output from the Camera,

    // create a CameraController.
    _controller = CameraController(
      // Get a specific camera from the list of available cameras.
      widget.camera,
      // Define the resolution to use.
      ResolutionPreset.medium,
    );

    // Next, initialize the controller. This returns a Future.
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    // Dispose of the controller when the widget is disposed.
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App state changed before we got the chance to initialize.
    if (_controller == null || !_controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_controller != null) {
        //  onNewCameraSelected(controller.description);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    // 240 is the width of scanner window in design draft of width 414.
    final windowHeight = screenSize.height / 2;
    final windowWidth = screenSize.width - 32;
    final _validRect = Rect.fromLTWH(16, 24, windowWidth, windowWidth);
    return Scaffold(
      appBar: AppBar(title: const Text('Take a picture')),
      // You must wait until the controller is initialized before displaying the
      // camera preview. Use a FutureBuilder to display a loading spinner until the
      // controller has finished initializing.
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            // If the Future is complete, display the preview.
            return Stack(
              alignment: Alignment.bottomCenter,
              children: [
                CameraPreview(_controller),

                // Positioned.fromRect(
                //   rect: _validRect,
                //   child: CameraPreview(_controller2),
                // ),
                CustomPaint(
                    painter: CameraWindowPainter(
                      windowRect: _validRect,
                      overlayColor: Colors.red,
                    ),
                    child: SizedBox.fromSize(
                      size: screenSize,
                    )),
                // SizedBox(
                //   height: 50,
                //   width: 50,
                //   child: ColoredBox(color: Colors.red),
                // ),

                // SizedBox(
                //   height: 50,
                //   width: 50,
                //   child: ColoredBox(color: Colors.black),
                // ),
              ],
            );
          } else {
            // Otherwise, display a loading indicator.
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        // Provide an onPressed callback.
        onPressed: () async {
          // Take the Picture in a try / catch block. If anything goes wrong,
          // catch the error.
          try {
            // Ensure that the camera is initialized.
            await _initializeControllerFuture;

            // Attempt to take a picture and get the file `image`
            // where it was saved.
            final image = await _controller.takePicture();

            // If the picture was taken, display it on a new screen.
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => DisplayPictureScreen(
                  // Pass the automatically generated path to
                  // the DisplayPictureScreen widget.
                  imagePath: image.path,
                ),
              ),
            );
          } catch (e) {
            // If an error occurs, log the error to the console.
            print(e);
          }
        },
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}

Future<img.Image> getImage(String path) async {
  final bytes = await File(path).readAsBytes();
  // print('imageInbytes' + bytes.length.toString());
  final image = img.decodeImage(bytes);
  //print('Mero' + image!.getBytes().length.toString());
  // final modifiedImage = Image.memory(bytes);
  return image!;
}

// Copyright (c) 2020 The Khalti Authors. All rights reserved.

class CameraWindowPainter extends CustomPainter {
  final Rect windowRect;
  final Color overlayColor;
  final bool closeWindow;
  final Color borderColor;

  CameraWindowPainter({
    required this.windowRect,
    required this.overlayColor,
    this.borderColor = Colors.yellow,
    this.closeWindow = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const radius = Radius.circular(10);

    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final windowRRect = RRect.fromRectAndRadius(windowRect, radius);
    final overlayPaint = Paint()..color = overlayColor.withOpacity(0.8);

    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(screenRect),
          Path()..addRRect(windowRRect),
        ),
        overlayPaint,
      );

    if (closeWindow) {
      canvas.drawRect(windowRect, overlayPaint);
    }
  }

  @override
  bool shouldRepaint(CameraWindowPainter oldDelegate) => oldDelegate.closeWindow != closeWindow || oldDelegate.borderColor != borderColor;
}
