part of '../compose_page.dart';

const List<Color> _kGaldenPalette = [
  Color(0xFFFFFFFF),
  Color(0xFFF44F44),
  Color(0xFFFF8F00),
  Color(0xFFEECC28),
  Color(0xFFF6EF1B),
  Color(0xFFC1E823),
  Color(0xFF85E41D),
  Color(0xFF64B31C),
  Color(0xFF0AD849),
  Color(0xFF0EE6B4),
  Color(0xFF22B4E0),
  Color(0xFF208CE8),
  Color(0xFF4C5AFF),
  Color(0xFF8858FD),
  Color(0xFFBB7EF2),
  Color(0xFFD800FF),
  Color(0xFFFF50B0),
  Color(0xFFFFC7C7),
  Color(0xFF808080),
  Color(0xFF000000),
];


class _ColorPickerPopup extends StatelessWidget {
  final Color? activeColor;
  final ValueChanged<Color> onColorSelected;
  final VoidCallback onClearColor;

  const _ColorPickerPopup({
    required this.activeColor,
    required this.onColorSelected,
    required this.onClearColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final popupBg = isDark ? const Color(0xFF2C2C2E) : Colors.white;
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    return Material(
      color: popupBg,
      borderRadius: BorderRadius.circular(12),
      elevation: 8,
      shadowColor: Colors.black38,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: onClearColor,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '清除顏色',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 5 * 28.0 + 4 * 4.0, // 5 columns × swatch + gaps
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _kGaldenPalette.map((color) {
                  final isActive = activeColor == color;
                  final isWhite = color == const Color(0xFFFFFFFF);
                  return GestureDetector(
                    onTap: () => onColorSelected(color),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                        border: isActive
                            ? Border.all(
                                color: AppTheme.accentColor, width: 2.5)
                            : isWhite
                                ? Border.all(color: borderColor, width: 1)
                                : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: AppTheme.accentColor
                                      .withValues(alpha: 0.4),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _RichTextToolbar extends StatefulWidget {
  final QuillController controller;
  final Future<String> Function(File) imagePickCallback;
  final bool showSmileyButton;
  final bool isSmileyKeyboardOpen;
  final VoidCallback? onToggleSmileyKeyboard;
  final bool applyBottomSafeArea;

  const _RichTextToolbar({
    required this.controller,
    required this.imagePickCallback,
    this.showSmileyButton = false,
    this.isSmileyKeyboardOpen = false,
    this.onToggleSmileyKeyboard,
    this.applyBottomSafeArea = true,
  });

  @override
  State<_RichTextToolbar> createState() => _RichTextToolbarState();
}

class _RichTextToolbarState extends State<_RichTextToolbar> {
  late _ToolbarSelection _selection;

  OverlayEntry? _colorOverlay;
  final GlobalKey _colorBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selection = (
      bold: false,
      italic: false,
      underline: false,
      strike: false,
      center: false,
      right: false,
      h1: false,
      h2: false,
      h3: false,
      color: null,
    );
    widget.controller.addListener(_onSelectionChanged);
  }

  @override
  void dispose() {
    _dismissColorPicker(updateUi: false);
    widget.controller.removeListener(_onSelectionChanged);
    super.dispose();
  }

  void _onSelectionChanged() {
    final style = widget.controller.getSelectionStyle();
    final attrs = style.attributes;

    final align = attrs[Attribute.align.key];
    final colorValue = attrs[Attribute.color.key]?.value as String?;

    Color? parsedColor;
    if (colorValue != null && colorValue.startsWith('#')) {
      try {
        parsedColor = Color(
          int.parse(colorValue.replaceFirst('#', ''), radix: 16) | 0xFF000000,
        );
      } catch (_) {}
    }

    final isBold = attrs.containsKey(Attribute.bold.key);
    final isItalic = attrs.containsKey(Attribute.italic.key);
    final isUnderline = attrs.containsKey(Attribute.underline.key);
    final isStrikethrough = attrs.containsKey(Attribute.strikeThrough.key);

    final newSelection = (
      bold: isBold,
      italic: isItalic,
      underline: isUnderline,
      strike: isStrikethrough,
      center: align?.value == 'center',
      right: align?.value == 'right',
      h1: attrs[Attribute.font.key]?.value == 'h1',
      h2: attrs[Attribute.font.key]?.value == 'h2',
      h3: attrs[Attribute.font.key]?.value == 'h3',
      color: parsedColor,
    );

    if (newSelection == _selection) return;

    setState(() => _selection = newSelection);
  }


  void _toggle(Attribute attribute, bool isActive) {
    widget.controller.formatSelection(
      isActive ? Attribute.clone(attribute, null) : attribute,
    );
  }

  void _toggleAlignment(Attribute attribute, bool isActive) {
    widget.controller.formatSelection(
      isActive ? Attribute.clone(Attribute.align, null) : attribute,
    );
  }

  void _toggleSize(String sizeValue, bool isActive) {
    widget.controller.formatSelection(
      isActive
          ? Attribute.clone(Attribute.font, null)
          : Attribute.clone(Attribute.font, sizeValue),
    );
  }

  Future<void> _insertLink(BuildContext context) async {
    final url = await showDialog<String>(
      context: context,
      builder: (_) => const _UrlDialog(),
    );
    if (url == null || url.isEmpty) return;
    final selection = widget.controller.selection;
    if (selection.isCollapsed) {
      widget.controller.replaceText(selection.baseOffset, 0, url, null);
      widget.controller
          .formatText(selection.baseOffset, url.length, LinkAttribute(url));
    } else {
      widget.controller.formatSelection(LinkAttribute(url));
    }
  }

  Future<void> _insertImage(BuildContext context) async {
    final imageUrl = await showDialog<String>(
      context: context,
      builder: (_) =>
          _UrlDialog(imagePickCallback: widget.imagePickCallback),
    );
    if (imageUrl == null || imageUrl.isEmpty) return;

    if (!mounted) return;

    final index = widget.controller.selection.baseOffset;
    final length = widget.controller.selection.extentOffset - index;
    widget.controller
        .replaceText(index, length, BlockEmbed.image(imageUrl), null);
    widget.controller.updateSelection(
        TextSelection.collapsed(offset: index + 1), ChangeSource.local);
  }


  void _toggleColorPicker() {
    if (_colorOverlay != null) {
      _dismissColorPicker();
      return;
    }
    _showColorPicker();
  }

  void _showColorPicker() {
    final renderBox =
        _colorBtnKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final overlay = Overlay.of(context);
    final btnPosition = renderBox.localToGlobal(Offset.zero);

    const popupWidth = 5 * 28.0 + 4 * 4.0 + 20;

    _colorOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissColorPicker,
          child: Stack(
            children: [
              Positioned(
                left: btnPosition.dx,
                bottom: MediaQuery.sizeOf(context).height - btnPosition.dy + 4,
                width: popupWidth,
                child: GestureDetector(
                  onTap: () {}, // prevent taps inside from dismissing
                  child: _ColorPickerPopup(
                    activeColor: _selection.color,
                    onColorSelected: (color) {
                      _applyColor(color);
                      _dismissColorPicker();
                    },
                    onClearColor: () {
                      _clearColor();
                      _dismissColorPicker();
                    },
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );

    overlay.insert(_colorOverlay!);
    setState(() {});
  }

  void _dismissColorPicker({bool updateUi = true}) {
    _colorOverlay?.remove();
    _colorOverlay = null;
    if (updateUi && mounted) setState(() {});
  }

  void _applyColor(Color color) {
    final hex =
        '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    widget.controller.formatSelection(ColorAttribute(hex));
  }

  void _clearColor() {
    widget.controller.formatSelection(const ColorAttribute(null));
  }


  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final isColorPickerOpen = _colorOverlay != null;

    final toolbarBody = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Row(
        children: [
          if (widget.showSmileyButton &&
              widget.onToggleSmileyKeyboard != null) ...[
            // Emoji when system keyboard is up; keyboard icon when smiley panel is open.
            _ToolbarButton(
              icon: widget.isSmileyKeyboardOpen
                  ? Icons.keyboard_rounded
                  : Icons.emoji_emotions_outlined,
              isActive: widget.isSmileyKeyboardOpen,
              onPressed: widget.onToggleSmileyKeyboard!,
            ),
            const SizedBox(width: 3),
          ],
          _ToolbarButton(
            key: _colorBtnKey,
            icon: Icons.format_paint_rounded,
            isActive: isColorPickerOpen,
            iconColor: _selection.color,
            onPressed: _toggleColorPicker,
          ),

          _buildDivider(dividerColor),

          _ToolbarButton(
            icon: Icons.format_bold_rounded,
            isActive: _selection.bold,
            onPressed: () => _toggle(Attribute.bold, _selection.bold),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            icon: Icons.format_italic_rounded,
            isActive: _selection.italic,
            onPressed: () => _toggle(Attribute.italic, _selection.italic),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            icon: Icons.format_underlined_rounded,
            isActive: _selection.underline,
            onPressed: () => _toggle(Attribute.underline, _selection.underline),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            icon: Icons.format_strikethrough_rounded,
            isActive: _selection.strike,
            onPressed: () =>
                _toggle(Attribute.strikeThrough, _selection.strike),
          ),

          _buildDivider(dividerColor),

          _ToolbarButton(
            icon: Icons.format_align_center_rounded,
            isActive: _selection.center,
            onPressed: () => _toggleAlignment(
                Attribute.centerAlignment, _selection.center),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            icon: Icons.format_align_right_rounded,
            isActive: _selection.right,
            onPressed: () =>
                _toggleAlignment(Attribute.rightAlignment, _selection.right),
          ),

          _buildDivider(dividerColor),

          _ToolbarButton(
            label: 'H1',
            isActive: _selection.h1,
            onPressed: () => _toggleSize('h1', _selection.h1),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            label: 'H2',
            isActive: _selection.h2,
            onPressed: () => _toggleSize('h2', _selection.h2),
          ),
          const SizedBox(width: 3),
          _ToolbarButton(
            label: 'H3',
            isActive: _selection.h3,
            onPressed: () => _toggleSize('h3', _selection.h3),
          ),

          _buildDivider(dividerColor),

          _ToolbarButton(
            icon: Icons.link_rounded,
            isActive: false,
            onPressed: () => _insertLink(context),
          ),

          _ToolbarButton(
            icon: Icons.image_rounded,
            isActive: false,
            onPressed: () => _insertImage(context),
          ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: widget.applyBottomSafeArea
          ? SafeArea(top: false, child: toolbarBody)
          : toolbarBody,
    );
  }

  Widget _buildDivider(Color color) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: color,
      );
}


class _ToolbarButton extends StatelessWidget {
  final bool isActive;
  final VoidCallback onPressed;

  final IconData? icon;
  final String? label;
  final Color? iconColor;

  const _ToolbarButton({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.icon,
    this.label,
    this.iconColor,
  }) : assert(icon != null || label != null, 'Provide either an icon or a label');

  static const _activeBackground = AppTheme.primaryColor;
  static const _activeForeground = Colors.white;

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        canRequestFocus: false,
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? _activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: icon != null
              ? Icon(
                  icon,
                  size: 20,
                  color: isActive ? _activeForeground : iconColor ?? inactiveColor,
                )
              : Text(
                  label!,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _activeForeground : inactiveColor,
                  ),
                ),
        ),
      ),
    );
  }
}

typedef _ToolbarSelection = ({
  bool bold,
  bool italic,
  bool underline,
  bool strike,
  bool center,
  bool right,
  bool h1,
  bool h2,
  bool h3,
  Color? color,
});

/// URL input dialog for inserting links and images. Image mode
/// ([imagePickCallback] set) adds the gallery-upload path.
class _UrlDialog extends StatefulWidget {
  final Future<String> Function(File)? imagePickCallback;

  const _UrlDialog({this.imagePickCallback});

  @override
  State<_UrlDialog> createState() => _UrlDialogState();
}

class _UrlDialogState extends State<_UrlDialog> {
  final TextEditingController _urlController = TextEditingController();
  bool _isValidUrl = false;
  bool _isUrlDirty = false;
  bool _isUploading = false;

  bool get _isImageMode => widget.imagePickCallback != null;

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

  Future<void> _pickAndUploadImage() async {
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
      title: Text(_isImageMode ? '插入圖片' : '插入連結'),
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
              onSubmitted: (_) => _submit(),
              enabled: !_isUploading,
              decoration: InputDecoration(
                hintText: 'https://',
                labelText: _isImageMode ? '圖片 URL' : 'URL',
                errorText: (!_isValidUrl && _isUrlDirty)
                    ? (_isImageMode
                        ? '請輸入有效的圖片連結 (例如: https://...)'
                        : '請輸入有效的連結 (例如: https://...)')
                    : null,
              ),
            ),
            if (_isImageMode) ...[
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
          onPressed: (_isUploading || !_isValidUrl) ? null : _submit,
          child: const Text('確定'),
        ),
      ],
    );
  }
}
