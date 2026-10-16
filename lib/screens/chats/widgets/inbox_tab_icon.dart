import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers.dart';
import '../../../services/chat/chat_repository.dart';

/// Inbox tab icon with the total unread message count as a badge.
class InboxTabIcon extends StatelessWidget {
  const InboxTabIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<ProfileProvider, int?>((p) => p.userID);
    if (userId == null) return const Icon(Icons.inbox);
    return _InboxBadge(key: ValueKey(userId), userId: userId.toString());
  }
}

class _InboxBadge extends StatefulWidget {
  final String userId;

  const _InboxBadge({super.key, required this.userId});

  @override
  State<_InboxBadge> createState() => _InboxBadgeState();
}

class _InboxBadgeState extends State<_InboxBadge> {
  late final Stream<int> _unread = _subscribe();

  Stream<int> _subscribe() {
    try {
      return ChatRepository.instance.watchUnreadTotal(widget.userId);
    } catch (_) {
      return Stream<int>.value(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _unread,
      builder: (context, snapshot) {
        final count = snapshot.hasError ? 0 : (snapshot.data ?? 0);
        return Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.inbox),
        );
      },
    );
  }
}
