import 'package:flutter/material.dart';
class ImageBanner extends StatelessWidget{
    final String _assetPath;
    ImageBanner(this._assetPath);
    @override //overrides existing function provided by StatelessWidget In this case we are overriding build.
    Widget build(BuildContext context){
      return Container(
        constraints: BoxConstraints.expand(
          height: 200.0 //constrained to expand until height is 200px.
        ),
        decoration: BoxDecoration(color: Colors.grey),
        child: Image.asset(_assetPath, fit: BoxFit.cover)
      );//Boxfit.cover fills out the image
    }
  }
      //Scaffold materializes screen.