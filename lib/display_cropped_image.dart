import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class DisplayCroppedImage extends StatelessWidget {
  final String path;
  final Uint8List imageBytes;
  const DisplayCroppedImage({Key? key, required this.path, required this.imageBytes}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //final image = Image.file(File(path));

    return Image.memory(imageBytes);
    // return image;
  }
}
