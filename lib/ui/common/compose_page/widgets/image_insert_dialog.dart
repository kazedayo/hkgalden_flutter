part of '../compose_page.dart';

/// A dialog that prompts the user to enter an image URL or upload from their device.
/// Returns the image URL via [Navigator.pop], or `null` on cancel.
class _ImageInsertDialog extends StatefulWidget {
  final Future<String> Function(File)? imagePickCallback;

  const _ImageInsertDialog({this.imagePickCallback});

  @override
  State<_ImageInsertDialog> createState() => _ImageInsertDialogState();
}

class _ImageInsertDialogState extends State<_ImageInsertDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isUploading = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submitUrl(BuildContext context, UrlValidationState state) {
    if (!state.isValidUrl) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).pop(url);
  }

  Future<void> _pickAndUploadImage() async {
    if (widget.imagePickCallback == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1920,
    );
    if (pickedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final file = File(pickedFile.path);
      final imageUrl = await widget.imagePickCallback!(file);
      if (mounted && imageUrl.isNotEmpty) {
        Navigator.of(context).pop(imageUrl);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UrlValidationCubit(),
      child: BlocBuilder<UrlValidationCubit, UrlValidationState>(
          builder: (context, state) {
        return AlertDialog(
          title: const Text('插入圖片'),
          content: SizedBox(
            width: MediaQuery.sizeOf(context).width,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _urlController,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  textInputAction: TextInputAction.done,
                  onChanged: (text) =>
                      context.read<UrlValidationCubit>().validateUrl(text),
                  onSubmitted: (_) => _submitUrl(context, state),
                  decoration: InputDecoration(
                    hintText: 'https://',
                    labelText: '圖片 URL',
                    errorText: (!state.isValidUrl && state.isUrlDirty)
                        ? '請輸入有效的圖片連結 (例如: https://...)'
                        : null,
                  ),
                  enabled: !_isUploading,
                ),
                if (widget.imagePickCallback != null) ...[
                  const SizedBox(height: 16),
                  const Text('或'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.selectionColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isUploading ? null : _pickAndUploadImage,
                      icon: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.upload_file),
                      label: Text(_isUploading ? '上載中...' : '從裝置上載'),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  _isUploading ? null : () => Navigator.of(context).pop(null),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: (_isUploading || !state.isValidUrl)
                  ? null
                  : () => _submitUrl(context, state),
              child: const Text('確定'),
            ),
          ],
        );
      }),
    );
  }
}
