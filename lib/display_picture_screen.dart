// A widget that displays the picture taken by the user.
import 'dart:io';
import 'dart:math';

import 'package:cameraoverlay/display_cropped_image.dart';
import 'package:cameraoverlay/main.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;

class DisplayPictureScreen extends StatelessWidget {
  final String imagePath;

  const DisplayPictureScreen({Key? key, required this.imagePath}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    File file = File(imagePath);
    print('original' + file.toString());
    final screenSize = MediaQuery.of(context).size;
    // 240 is the width of scanner window in design draft of width 414.
    final windowHeight = screenSize.height / 2;
    final windowWidth = screenSize.width - 32;
    final _validRect = Rect.fromLTWH(16, 24, windowWidth, windowWidth);
    //final bytes = getImageBytes(imagePath);

    final image = Image.file(File(imagePath));
    // final image = img.decodeImage(bytes);

// final image2 = img.fill(image, color)
//     final image2 = copyCrop(image, x, y, w, h)

    return Scaffold(
      appBar: AppBar(title: const Text('Display the Picture')),
      // The image is stored as a file on the device. Use the `Image.file`
      // constructor with the given path to display the image.
      body: Stack(
        children: [
          Image.file(File(file.path)),
          CustomPaint(
            painter: CameraWindowPainter(
              windowRect: _validRect,
              overlayColor: Colors.red,
            ),
            child: SizedBox.fromSize(
              size: screenSize,
            ),
          ),
          TextButton(
            onPressed: () async {
              final convertedImage = await getImage(imagePath);
              print(image);
              print(convertedImage.height);
              final cropWidth = (convertedImage.width * convertedImage.width) / windowWidth;
              final croppedImage = copyCrop(convertedImage, 16, 24, windowWidth.toInt(), windowWidth.toInt() + 24);
              print('crop ko' + croppedImage.getBytes().length.toString());
              // final modifiedImage = Image.memory(croppedImage);
              final croppedImageFile = await imageToFile(croppedImage: croppedImage);
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => DisplayCroppedImage(
                    // Pass the automatically generated path to
                    // the DisplayPictureScreen widget.
                    path: croppedImageFile.path,
                    imageBytes: convertedImage.getBytes(),
                  ),
                ),
              );
            },
            child: Text('Hello'),
          )
        ],
      ),
    );
  }

  Future<File> imageToFile({required img.Image croppedImage}) async {
    Directory tempDir = await getTemporaryDirectory();

// get temporary path from temporary directory.
    String tempPath = tempDir.path;
    print('path1' + tempPath);
    File file = File('$tempPath/profile-${Random.secure().nextDouble()}.jpg');
    await file.writeAsBytes(img.encodePng(croppedImage, level: 6));
    final fileLength = await file.length();
    print('file length' + fileLength.toString());
    return file;
  }
}

img.Image copyCrop(img.Image src, int x, int y, int w, int h) {
  final width = src.width;
  final height = src.height;
  // Make sure crop rectangle is within the range of the src image.
  x = x.clamp(0, width - 1).toInt();
  y = y.clamp(0, height - 1).toInt();
  if (x + w > width) {
    w = width - x;
  }
  if (y + h > height) {
    h = height - y;
  }

  final dst = img.Image(w, h, channels: src.channels, exif: src.exif, iccp: src.iccProfile);

  for (var yi = 0, sy = y; yi < h; ++yi, ++sy) {
    for (var xi = 0, sx = x; xi < w; ++xi, ++sx) {
      dst.setPixel(xi, yi, src.getPixel(sx, sy));
    }
  }

  return dst;
}
