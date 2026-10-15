import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:persistent_bottom_nav_bar/persistent_bottom_nav_bar.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers.dart';
import '../../services/chat/chat_repository.dart';
import 'chat_screen.dart';
import 'widgets/inbox_avatar.dart';

/// The Inbox tab: the signed-in user's 1:1 conversations, newest first.
class AllChatsScreen extends StatelessWidget {
  const AllChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId = context.select<ProfileProvider, int?>((p) => p.userID);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: false,
        automaticallyImplyLeading: false,
      ),
      body: userId == null
          ? const _InboxMessage(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to see your messages',
            )
          : _InboxBody(key: ValueKey(userId), userId: userId),
    );
  }
}

class _InboxBody extends StatefulWidget {
  final int userId;

  const _InboxBody({super.key, required this.userId});

  @override
  State<_InboxBody> createState() => _InboxBodyState();
}

class _InboxBodyState extends State<_InboxBody> {
  final TextEditingController _search = TextEditingController();
  late Stream<List<ChatSummary>> _inbox;
  String _query = '';

  String get _myId => widget.userId.toString();

  @override
  void initState() {
    super.initState();
    _inbox = _subscribe();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Stream<List<ChatSummary>> _subscribe() {
    try {
      return ChatRepository.instance.watchInbox(_myId);
    } catch (e) {
      return Stream<List<ChatSummary>>.error(e);
    }
  }

  void _retry() => setState(() => _inbox = _subscribe());

  void _open(ChatSummary chat, int otherId) {
    final profile = context.read<ProfileProvider>();
    final myName = '${profile.firstName} ${profile.lastName}'.trim();
    PersistentNavBarNavigator.pushNewScreen(
      context,
      screen: CioChatScreen(
        chattingWithName: chat.otherName,
        chattingWithID: otherId,
        currentUserID: widget.userId,
        currentUserName: myName.isEmpty ? profile.firstName : myName,
      ),
      withNavBar: false,
      pageTransitionAnimation: PageTransitionAnimation.slideRight,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ChatSummary>>(
      stream: _inbox,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _InboxMessage(
            icon: Icons.cloud_off_rounded,
            title: "Couldn't load your messages",
            subtitle: 'Check your connection and try again.',
            action: FilledButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(backgroundColor: kPrimaryColor),
            ),
          );
        }
        if (!snapshot.hasData) return const _InboxSkeleton();

        final chats = snapshot.data!
            .where((c) => int.tryParse(c.otherId) != null && c.otherId != _myId)
            .toList();
        if (chats.isEmpty) {
          return const _InboxMessage(
            icon: Icons.forum_outlined,
            title: 'No messages yet',
            subtitle: "Start a conversation from a delegate's profile in Networking.",
          );
        }

        final q = _query.trim().toLowerCase();
        final visible =
            q.isEmpty ? chats : chats.where((c) => c.otherName.toLowerCase().contains(q)).toList();

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _SearchField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                onClear: () {
                  _search.clear();
                  setState(() => _query = '');
                },
              ),
            ),
            Expanded(
              child: visible.isEmpty
                  ? _InboxMessage(
                      icon: Icons.search_off_rounded,
                      title: 'No matches',
                      subtitle: 'Nobody called "${_query.trim()}" in your messages.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 24),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 84),
                      itemBuilder: (context, i) {
                        final chat = visible[i];
                        return _InboxRow(
                          key: ValueKey(chat.chatId),
                          chat: chat,
                          onTap: () => _open(chat, int.parse(chat.otherId)),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search messages',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear',
                icon: const Icon(Icons.close_rounded),
                onPressed: onClear,
              ),
        isDense: true,
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _InboxRow extends StatelessWidget {
  final ChatSummary chat;
  final VoidCallback onTap;

  const _InboxRow({super.key, required this.chat, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unread = chat.unread > 0;
    final preview = chat.lastText.isEmpty
        ? ''
        : (chat.lastIsMine ? 'You: ${chat.lastText}' : chat.lastText);
    final muted = scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            InboxAvatar(name: chat.otherName, photoId: chat.otherPhoto),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.otherName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatInboxTime(chat.updatedAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: unread ? kPrimaryColor : muted,
                          fontWeight: unread ? FontWeight.w600 : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: unread ? scheme.onSurface : muted,
                            fontWeight: unread ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                      if (unread) ...[
                        const SizedBox(width: 8),
                        _UnreadPill(count: chat.unread),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnreadPill extends StatelessWidget {
  final int count;

  const _UnreadPill({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: kPrimaryColor,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

/// Today 'HH:mm', yesterday 'Yesterday', within 6 days the weekday, else 'd MMM'.
String formatInboxTime(DateTime? at, {DateTime? now}) {
  if (at == null) return '';
  final local = at.toLocal();
  final n = now ?? DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(local.year, local.month, local.day);
  final days = today.difference(day).inDays;
  if (days <= 0) return DateFormat.Hm().format(local);
  if (days == 1) return 'Yesterday';
  if (days <= 6) return DateFormat('EEE').format(local);
  return DateFormat('d MMM').format(local);
}

class _InboxMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const _InboxMessage({required this.icon, required this.title, this.subtitle, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: kPrimaryColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: kPrimaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Grey placeholder rows that gently pulse while the inbox loads.
class _InboxSkeleton extends StatefulWidget {
  const _InboxSkeleton();

  @override
  State<_InboxSkeleton> createState() => _InboxSkeletonState();
}

class _InboxSkeletonState extends State<_InboxSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.4,
    upperBound: 1,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08);
    Widget bar(double width, double height) => Container(
          width: width,
          height: height,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(6)),
        );
    return FadeTransition(
      opacity: _pulse,
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 64),
        itemCount: 7,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: base, shape: BoxShape.circle),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    bar(i.isEven ? 140 : 110, 14),
                    const SizedBox(height: 8),
                    bar(i.isEven ? 200 : 170, 12),
                  ],
                ),
              ),
              bar(36, 10),
            ],
          ),
        ),
      ),
    );
  }
}
