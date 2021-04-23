import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

class ImageLoadingError extends StatelessWidget {
  final String error;

  const ImageLoadingError(this.error);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.error_rounded,
          color: Colors.grey,
        ),
        const SizedBox(
          width: 10,
        ),
        Expanded(
          child: AutoSizeText(
            '圖片載入錯誤: $error',
            style: Theme.of(context).textTheme.caption,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
