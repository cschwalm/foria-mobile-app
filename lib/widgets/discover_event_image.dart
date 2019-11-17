import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'errors/image_unavailable.dart';

///
/// Cached image for the event
///
class DiscoverEventImage extends StatelessWidget {

  final String _imageUrl;

  DiscoverEventImage(this._imageUrl);

  @override
  Widget build(BuildContext context) {
    return _imageUrl == null ? Container() : CachedNetworkImage(
      placeholder: (context, url) =>
          CupertinoActivityIndicator(),
      errorWidget: (context, url, error) {
        return ImageUnavailable();
      },
      imageUrl: _imageUrl,
      imageBuilder: (context, imageProvider) =>
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(2)),
              image: DecorationImage(
                image: imageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
    );
  }
}