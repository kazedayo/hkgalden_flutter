part of '../compose_page.dart';

/// Custom-keyboard-style smiley panel: pack strip + scrollable smiley grid.
///
/// Shown only when invoked from the toolbar; sized like a soft keyboard.
///
/// Scroll views use dedicated controllers with [primary] false so they do **not**
/// attach to the bar-modal [PrimaryScrollController] from
/// `showBarModalBottomSheet`. That attachment made scrolling the pane drive the
/// sheet dismiss gesture.
class _SmileyPane extends StatefulWidget {
  final QuillController controller;
  final List<SmileyPack> packs;

  const _SmileyPane({
    required this.controller,
    required this.packs,
  });

  @override
  State<_SmileyPane> createState() => _SmileyPaneState();
}

class _SmileyPaneState extends State<_SmileyPane> {
  late String? _currentPackId;
  late final ScrollController _packsScrollController;
  late final ScrollController _smiliesScrollController;

  @override
  void initState() {
    super.initState();
    _currentPackId = selectDefaultSmileyPackId(widget.packs);
    _packsScrollController = ScrollController();
    _smiliesScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _SmileyPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.packs != widget.packs) {
      final stillValid =
          findSmileyPackById(widget.packs, _currentPackId) != null;
      if (!stillValid) {
        _currentPackId = selectDefaultSmileyPackId(widget.packs);
      }
    }
  }

  @override
  void dispose() {
    _packsScrollController.dispose();
    _smiliesScrollController.dispose();
    super.dispose();
  }

  SmileyPack? get _currentPack =>
      findSmileyPackById(widget.packs, _currentPackId);

  void _onPackTap(String packId) {
    if (_currentPackId == packId) return;
    setState(() => _currentPackId = packId);
  }

  void _onSmileyTap(Smiley smiley) {
    final pack = _currentPack;
    if (pack == null) return;
    // Insert while system keyboard stays suppressed (controller.readOnly).
    widget.controller.skipRequestKeyboard = true;
    SmileyEmbed.insertInto(widget.controller, pack.id, smiley);
    SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  }

  @override
  Widget build(BuildContext context) {
    if (widget.packs.isEmpty) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? Colors.white24 : Colors.black12;
    final surface = Theme.of(context).colorScheme.surface;
    final pack = _currentPack;
    final screenHeight = MediaQuery.sizeOf(context).height;
    // Approximate soft-keyboard height without covering the whole compose UI.
    final panelHeight = (screenHeight * 0.32).clamp(220.0, 300.0);

    return Material(
      color: surface,
      child: SafeArea(
        top: false,
        // Swallow scroll notifications so modal_bottom_sheet does not treat
        // smiley-pane scrolling as a dismiss drag (in addition to primary:false).
        child: NotificationListener<ScrollNotification>(
          onNotification: (_) => true,
          child: Container(
            height: panelHeight,
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Pack list (web: .packs) — first smiley of each pack as icon
                SizedBox(
                  width: 56,
                  child: ListView.builder(
                    controller: _packsScrollController,
                    primary: false,
                    padding: const EdgeInsets.symmetric(
                        vertical: 6, horizontal: 6),
                    itemCount: widget.packs.length,
                    itemBuilder: (context, index) {
                      final p = widget.packs[index];
                      if (p.smilies.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final first = p.smilies.first;
                      final selected = p.id == _currentPackId;
                      final url =
                          smileyGifUrl(packId: p.id, smileyId: first.id);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Material(
                          color: selected
                              ? AppTheme.primaryColor.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(6),
                            onTap: () => _onPackTap(p.id),
                            child: Padding(
                              padding: const EdgeInsets.all(6),
                              child: Image.network(
                                url,
                                width: 28,
                                height: 28,
                                fit: BoxFit.contain,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.emoji_emotions_outlined,
                                  size: 22,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                VerticalDivider(width: 1, thickness: 1, color: borderColor),
                // Smiley grid (web: .smilies)
                Expanded(
                  child: pack == null || pack.smilies.isEmpty
                      ? const SizedBox.shrink()
                      : SingleChildScrollView(
                          controller: _smiliesScrollController,
                          primary: false,
                          padding: const EdgeInsets.all(8),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: pack.smilies.map((smiley) {
                              final url = smileyGifUrl(
                                  packId: pack.id, smileyId: smiley.id);
                              return InkWell(
                                borderRadius: BorderRadius.circular(4),
                                onTap: () => _onSmileyTap(smiley),
                                child: Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: Image.network(
                                    url,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.contain,
                                    gaplessPlayback: true,
                                    semanticLabel: smiley.alt,
                                    errorBuilder:
                                        (context, error, stackTrace) => Icon(
                                      Icons.broken_image_outlined,
                                      size: 20,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
