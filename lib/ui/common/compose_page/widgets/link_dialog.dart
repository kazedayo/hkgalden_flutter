part of '../compose_page.dart';

/// A simple dialog that prompts the user to enter a URL for a hyperlink.
/// Returns the trimmed URL string via [Navigator.pop], or `null` on cancel.
class _LinkDialog extends StatefulWidget {
  const _LinkDialog();

  @override
  State<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends State<_LinkDialog> {
  final TextEditingController _urlController = TextEditingController();

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context, UrlValidationState state) {
    if (!state.isValidUrl) return;
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    Navigator.of(context).pop(url);
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UrlValidationCubit(),
      child: BlocBuilder<UrlValidationCubit, UrlValidationState>(
        builder: (context, state) {
          return AlertDialog(
            title: const Text('插入連結'),
            content: SizedBox(
              width: MediaQuery.sizeOf(context).width,
              child: TextField(
                controller: _urlController,
                autofocus: true,
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                onChanged: (text) =>
                    context.read<UrlValidationCubit>().validateUrl(text),
                onSubmitted: (_) => _submit(context, state),
                decoration: InputDecoration(
                  hintText: 'https://',
                  labelText: 'URL',
                  errorText: (!state.isValidUrl && state.isUrlDirty)
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
                onPressed:
                    state.isValidUrl ? () => _submit(context, state) : null,
                child: const Text('確定'),
              ),
            ],
          );
        },
      ),
    );
  }
}
