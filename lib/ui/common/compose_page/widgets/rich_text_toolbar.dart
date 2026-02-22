part of '../compose_page.dart';

/// The 20-colour palette used on the hkGalden website (exact hex values).
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

// ── Colour picker popup ────────────────────────────────────────────────────────

/// A 4×5 grid of colour swatches that fires [onColorSelected] when a colour is
/// tapped, or [onClearColor] when the user wants to remove the current colour.
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
            // ── Clear / default row ──────────────────────────────────────────
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
            // ── 4 × 5 palette grid ───────────────────────────────────────────
            SizedBox(
              width: 5 * 28.0 + 4 * 4.0, // 5 columns × swatch + gaps
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: _kGaldenPalette.map((color) {
                  final isActive = activeColor == color;
                  // White swatch needs a visible border on all themes.
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

// ── Toolbar ────────────────────────────────────────────────────────────────────

/// A scrollable formatting toolbar that keeps its buttons in sync with the
/// current [QuillController] selection state.
///
/// Supported operations: Text colour, Bold, Italic, Underline, Strikethrough,
/// Center/Right align, H1/H2/H3, and link insertion.
class _RichTextToolbar extends StatefulWidget {
  final QuillController controller;
  final Future<String> Function(File)? imagePickCallback;

  const _RichTextToolbar({
    required this.controller,
    this.imagePickCallback,
  });

  @override
  State<_RichTextToolbar> createState() => _RichTextToolbarState();
}

class _RichTextToolbarState extends State<_RichTextToolbar> {
  // ── Inline style toggles ────────────────────────────────────────────────
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  bool _isStrikethrough = false;

  // ── Block-level toggles ─────────────────────────────────────────────────
  bool _isCenterAlign = false;
  bool _isRightAlign = false;
  bool _isH1 = false;
  bool _isH2 = false;
  bool _isH3 = false;

  // ── Color ────────────────────────────────────────────────────────────────
  Color? _activeColor;

  // ── Color picker overlay ─────────────────────────────────────────────────
  OverlayEntry? _colorOverlay;
  final GlobalKey _colorBtnKey = GlobalKey();

  @override
  void initState() {
    super.initState();
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

    setState(() {
      _isBold = attrs.containsKey(Attribute.bold.key);
      _isItalic = attrs.containsKey(Attribute.italic.key);
      _isUnderline = attrs.containsKey(Attribute.underline.key);
      _isStrikethrough = attrs.containsKey(Attribute.strikeThrough.key);
      _isCenterAlign = align?.value == 'center';
      _isRightAlign = align?.value == 'right';
      _isH1 = attrs[Attribute.font.key]?.value == 'h1';
      _isH2 = attrs[Attribute.font.key]?.value == 'h2';
      _isH3 = attrs[Attribute.font.key]?.value == 'h3';
      _activeColor = parsedColor;
    });
  }

  // ── Toggle helpers ────────────────────────────────────────────────────────

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
      builder: (_) => const _LinkDialog(),
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
      builder: (_) => _ImageInsertDialog(
        imagePickCallback: widget.imagePickCallback,
      ),
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

  // ── Color picker ──────────────────────────────────────────────────────────

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

    // Calculate where the popup should appear (above the button if near bottom).
    const popupWidth = 5 * 28.0 + 4 * 4.0 + 20; // swatches + gaps + padding

    _colorOverlay = OverlayEntry(
      builder: (ctx) {
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _dismissColorPicker,
          child: Stack(
            children: [
              Positioned(
                left: btnPosition.dx,
                // Place the popup above the toolbar button.
                bottom: MediaQuery.sizeOf(context).height - btnPosition.dy + 4,
                width: popupWidth,
                child: GestureDetector(
                  onTap: () {}, // prevent taps inside from dismissing
                  child: _ColorPickerPopup(
                    activeColor: _activeColor,
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final dividerColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12);
    final isColorPickerOpen = _colorOverlay != null;

    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              // ── Text colour ────────────────────────────────────────────────
              _ColorButton(
                key: _colorBtnKey,
                activeColor: _activeColor,
                isPickerOpen: isColorPickerOpen,
                onPressed: _toggleColorPicker,
              ),

              _buildDivider(dividerColor),

              // ── Inline formatting ──────────────────────────────────────────
              _ToolbarButton(
                icon: Icons.format_bold_rounded,
                isActive: _isBold,
                onPressed: () => _toggle(Attribute.bold, _isBold),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                icon: Icons.format_italic_rounded,
                isActive: _isItalic,
                onPressed: () => _toggle(Attribute.italic, _isItalic),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                icon: Icons.format_underlined_rounded,
                isActive: _isUnderline,
                onPressed: () => _toggle(Attribute.underline, _isUnderline),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                icon: Icons.format_strikethrough_rounded,
                isActive: _isStrikethrough,
                onPressed: () =>
                    _toggle(Attribute.strikeThrough, _isStrikethrough),
              ),

              _buildDivider(dividerColor),

              // ── Alignment ──────────────────────────────────────────────────
              _ToolbarButton(
                icon: Icons.format_align_center_rounded,
                isActive: _isCenterAlign,
                onPressed: () =>
                    _toggleAlignment(Attribute.centerAlignment, _isCenterAlign),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                icon: Icons.format_align_right_rounded,
                isActive: _isRightAlign,
                onPressed: () =>
                    _toggleAlignment(Attribute.rightAlignment, _isRightAlign),
              ),

              _buildDivider(dividerColor),

              // ── Headings ───────────────────────────────────────────────────
              _ToolbarButton(
                label: 'H1',
                isActive: _isH1,
                onPressed: () => _toggleSize('h1', _isH1),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                label: 'H2',
                isActive: _isH2,
                onPressed: () => _toggleSize('h2', _isH2),
              ),
              const SizedBox(width: 3),
              _ToolbarButton(
                label: 'H3',
                isActive: _isH3,
                onPressed: () => _toggleSize('h3', _isH3),
              ),

              _buildDivider(dividerColor),

              // ── Link ───────────────────────────────────────────────────────
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
        ),
      ),
    );
  }

  Widget _buildDivider(Color color) => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        color: color,
      );
}

// ── Colour button widget ───────────────────────────────────────────────────────

/// A toolbar button that shows the current text colour as a coloured stripe
/// below the paint-bucket icon. Tapping it opens/closes the colour palette.
class _ColorButton extends StatelessWidget {
  final Color? activeColor;
  final bool isPickerOpen;
  final VoidCallback onPressed;

  const _ColorButton({
    super.key,
    required this.activeColor,
    required this.isPickerOpen,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final inactiveColor =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    final iconColor =
        isPickerOpen ? Colors.white : activeColor ?? inactiveColor;

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
            color: isPickerOpen ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.format_paint_rounded,
            size: 20,
            color: iconColor,
          ),
        ),
      ),
    );
  }
}
