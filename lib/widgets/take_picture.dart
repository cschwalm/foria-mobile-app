import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as syspaths;

class TakePicture extends StatefulWidget {
  final Function onSelectImage;

  TakePicture(this.onSelectImage);

  @override
  _TakePictureState createState() => _TakePictureState();
}

class _TakePictureState extends State<TakePicture> {
  File _storedImage;

  Future<void> _takePicture() async {
    final imageFile =
    await ImagePicker.pickImage(source: ImageSource.camera, maxWidth: 600);
    if (imageFile == null){
      return;
    }
    setState(() {
      _storedImage = imageFile;
    });
    final appDir = await syspaths.getApplicationDocumentsDirectory();
    final fileName = path.basename(imageFile.path);
    final savedImage = await imageFile.copy('${appDir.path}/$fileName');
    widget.onSelectImage(savedImage);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      height: 100,
      decoration: BoxDecoration(
        border: Border.all(
          width: 1,
          color: Colors.grey,
        ),
      ),
      child: _storedImage != null
          ? Image.file(
        _storedImage,
        fit: BoxFit.cover,
        width: double.infinity,
      )
          : Text(
        'No image taken',
        textAlign: TextAlign.center,
      ),
      alignment: Alignment.center,
    );
  }
}