import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../constants.dart';
import '../../../services/chat/chat_models.dart';

/// One message bubble in a conversation.
///
/// [groupedWithOlder] / [groupedWithNewer] say whether the message visually
/// above / below is from the same sender within a few minutes; grouped
/// bubbles sit closer together and have a tighter corner on the joined side.
class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;
  final bool groupedWithOlder;
  final bool groupedWithNewer;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.groupedWithOlder = false,
    this.groupedWithNewer = false,
  });

  static const double _r = 18;
  static const double _tight = 5;

  BorderRadius get _radius {
    const big = Radius.circular(_r);
    const small = Radius.circular(_tight);
    if (isMine) {
      return BorderRadius.only(
        topLeft: big,
        bottomLeft: big,
        topRight: groupedWithOlder ? small : big,
        bottomRight: groupedWithNewer ? small : big,
      );
    }
    return BorderRadius.only(
      topRight: big,
      bottomRight: big,
      topLeft: groupedWithOlder ? small : big,
      bottomLeft: groupedWithNewer ? small : big,
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(
        content: Text('Copied'),
        duration: Duration(seconds: 1),
      ));
  }

  void _openImage(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: InteractiveViewer(
            maxScale: 4,
            child: CachedNetworkImage(
              imageUrl: message.text,
              fit: BoxFit.contain,
              placeholder: (context, url) =>
                  const CircularProgressIndicator(color: Colors.white),
              errorWidget: (context, url, error) =>
                  const Icon(Icons.broken_image_outlined, color: Colors.white54, size: 48),
            ),
          ),
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isMine ? kPrimaryColor : scheme.surfaceContainerHighest;
    final fg = isMine ? Colors.white : scheme.onSurface;
    final metaColor = isMine ? Colors.white70 : scheme.onSurfaceVariant;
    final time = DateFormat.Hm().format(message.sentAt ?? DateTime.now());

    final meta = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(time, style: TextStyle(fontSize: 10.5, color: metaColor)),
        if (isMine) ...[
          const SizedBox(width: 3),
          _StatusIcon(message: message),
        ],
      ],
    );

    final Widget content;
    if (message.type != 0) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: message.text,
              width: 200,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 200,
                height: 200,
                color: scheme.surfaceContainerHigh,
                alignment: Alignment.center,
                child: const CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => Image.asset(
                'assets/images/imagenotavailable.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          meta,
        ],
      );
    } else {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message.text,
            style: TextStyle(color: fg, fontSize: 15.5, height: 1.3),
          ),
          const SizedBox(height: 2),
          meta,
        ],
      );
    }

    final maxWidth = MediaQuery.sizeOf(context).width * 0.78;

    return Padding(
      padding: EdgeInsets.only(
        top: groupedWithOlder ? 1.5 : 6,
        bottom: groupedWithNewer ? 1.5 : 6,
      ),
      child: Align(
        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: message.type != 0 ? Colors.transparent : bg,
            borderRadius: _radius,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: message.type != 0 ? () => _openImage(context) : null,
              onLongPress: message.type == 0 ? () => _copy(context) : null,
              child: Padding(
                padding: message.type != 0
                    ? const EdgeInsets.all(2)
                    : const EdgeInsets.fromLTRB(12, 8, 10, 6),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusIcon extends StatelessWidget {
  final ChatMessage message;

  const _StatusIcon({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.pending) {
      return const Icon(Icons.schedule, size: 13, color: Colors.white70);
    }
    if (message.isRead) {
      return const Icon(Icons.done_all, size: 15, color: Color(0xFFE1F5FE));
    }
    return const Icon(Icons.done, size: 14, color: Colors.white70);
  }
}
