part of '../compose_page.dart';

class _ImageInsertDialog extends StatefulWidget {
  final Future<String> Function(File)? imagePickCallback;

  const _ImageInsertDialog({this.imagePickCallback});

  @override
  State<_ImageInsertDialog> createState() => _ImageInsertDialogState();
}

class _ImageInsertDialogState extends State<_ImageInsertDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isUploading = false;
  bool _isValidUrl = false;
  bool _isUrlDirty = false;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _onUrlChanged(String text) {
    final trimmed = text.trim();
    setState(() {
      _isUrlDirty = trimmed.isNotEmpty;
      _isValidUrl = Uri.tryParse(trimmed)?.hasAbsolutePath ?? false;
    });
  }

  void _submitUrl() {
    if (!_isValidUrl) return;
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
              onChanged: _onUrlChanged,
              onSubmitted: (_) => _submitUrl(),
              decoration: InputDecoration(
                hintText: 'https://',
                labelText: '圖片 URL',
                errorText: (!_isValidUrl && _isUrlDirty)
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
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: (_isUploading || !_isValidUrl) ? null : _submitUrl,
          child: const Text('確定'),
        ),
      ],
    );
  }
}
