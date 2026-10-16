import 'package:flutter/material.dart';

import '../../../constants.dart';

/// Attach button + text field + send button at the bottom of a conversation.
class ChatComposer extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback onSend;

  /// Opens the photo picker. Hidden when null.
  final VoidCallback? onAttach;

  /// True while a photo uploads; the attach button shows a spinner.
  final bool attaching;
  final bool enabled;

  const ChatComposer({
    super.key,
    required this.controller,
    required this.onSend,
    this.onAttach,
    this.attaching = false,
    this.focusNode,
    this.enabled = true,
  });

  @override
  State<ChatComposer> createState() => _ChatComposerState();
}

class _ChatComposerState extends State<ChatComposer> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _hasText = widget.controller.text.trim().isNotEmpty;
    widget.controller.addListener(_onChanged);
  }

  @override
  void didUpdateWidget(covariant ChatComposer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onChanged);
      widget.controller.addListener(_onChanged);
      _onChanged();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    final has = widget.controller.text.trim().isNotEmpty;
    if (has != _hasText) setState(() => _hasText = has);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final canSend = widget.enabled && _hasText;
    return Material(
      color: scheme.surface,
      elevation: 2,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(widget.onAttach == null ? 12 : 2, 8, 6, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.onAttach != null)
                IconButton(
                  tooltip: 'Send a photo',
                  onPressed: widget.enabled && !widget.attaching ? widget.onAttach : null,
                  icon: widget.attaching
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_photo_alternate_outlined),
                  color: kPrimaryColor,
                  disabledColor: scheme.onSurface.withValues(alpha: 0.3),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontSize: 15.5),
                  decoration: InputDecoration(
                    hintText: 'Message',
                    isDense: true,
                    filled: true,
                    fillColor: scheme.surfaceContainerHighest,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(22),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Send',
                onPressed: canSend ? widget.onSend : null,
                icon: const Icon(Icons.send_rounded),
                color: kPrimaryColor,
                disabledColor: scheme.onSurface.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
