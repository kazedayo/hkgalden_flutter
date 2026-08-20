part of '../compose_page.dart';

class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final TextEditingController _urlController = TextEditingController();
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

  void _submit() {
    if (!_isValidUrl) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('插入連結'),
      content: SizedBox(
        width: MediaQuery.sizeOf(context).width,
        child: TextField(
          controller: _urlController,
          autofocus: true,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.done,
          onChanged: _onUrlChanged,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'https://',
            labelText: 'URL',
            errorText: (!_isValidUrl && _isUrlDirty)
                ? '請輸入有效的連結 (例如: https://...)'
                : null,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: _isValidUrl ? _submit : null,
          child: const Text('確定'),
        ),
      ],
    );
  }
}
