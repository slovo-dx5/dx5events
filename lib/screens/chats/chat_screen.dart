import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../providers.dart';
import '../../services/chat/chat_repository.dart';
import 'widgets/chat_avatar.dart';
import 'widgets/chat_bubble.dart';
import 'widgets/chat_composer.dart';
import 'widgets/chat_day_separator.dart';

/// 1:1 conversation. All reads/writes go through [ChatRepository]; the
/// `onChatMessageCreated` Cloud Function maintains `chats/{chatId}` and sends
/// the push to the recipient.
class CioChatScreen extends StatefulWidget {
  final int currentUserID;
  final int chattingWithID;
  final String chattingWithName;
  final String currentUserName;

  const CioChatScreen({
    super.key,
    required this.chattingWithName,
    required this.chattingWithID,
    required this.currentUserID,
    required this.currentUserName,
  });

  @override
  State<CioChatScreen> createState() => _CioChatScreenState();
}

class _CioChatScreenState extends State<CioChatScreen> with WidgetsBindingObserver {
  static const Duration _groupWindow = Duration(minutes: 5);

  final ChatRepository _repo = ChatRepository.instance;
  final TextEditingController _text = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final FocusNode _focus = FocusNode();

  late final String _myId = '${widget.currentUserID}';
  late final String _otherId = '${widget.chattingWithID}';

  String? _chatId;
  Object? _error;

  int _limit = ChatRepository.pageSize;
  bool _hasMore = true;
  bool _loadingMore = false;
  bool _loaded = false;
  List<ChatMessage> _messages = const [];
  StreamSubscription<List<ChatMessage>>? _sub;
  StreamSubscription<int>? _unreadSub;

  bool _attaching = false;

  bool _resumed = true;
  Timer? _readDebounce;
  String? _lastIncomingId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final state = WidgetsBinding.instance.lifecycleState;
    _resumed = state == null || state == AppLifecycleState.resumed;
    _scroll.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _readDebounce?.cancel();
    _sub?.cancel();
    _unreadSub?.cancel();
    _scroll.dispose();
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    if (_resumed) _scheduleMarkRead();
  }

  Future<void> _init() async {
    try {
      final id = await _repo.resolveChatId(_myId, _otherId);
      if (!mounted) return;
      setState(() => _chatId = id);
      _subscribe();
      _markRead();
      // The Cloud Function may count a message as unread after this screen
      // already marked it read; clear it again while the chat is open.
      _unreadSub = _repo.watchUnread(id, _myId).listen((n) {
        if (n > 0) _scheduleMarkRead();
      }, onError: (Object e) => debugPrint('chat: unread watch failed: $e'));
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  void _subscribe() {
    final chatId = _chatId;
    if (chatId == null) return;
    _sub?.cancel();
    final requested = _limit;
    _sub = _repo.watchMessages(chatId, limit: requested).listen((msgs) {
      if (!mounted) return;
      setState(() {
        _messages = msgs;
        _loaded = true;
        _error = null;
        _loadingMore = false;
        _hasMore = msgs.length >= requested;
      });
      _onMessages(msgs);
    }, onError: (Object e) {
      if (!mounted) return;
      setState(() {
        _error = e;
        _loadingMore = false;
      });
    });
  }

  void _onScroll() {
    if (!_scroll.hasClients || !_hasMore || _loadingMore || !_loaded) return;
    final pos = _scroll.position;
    // Reversed list: the oldest messages are at maxScrollExtent.
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      setState(() {
        _loadingMore = true;
        _limit += ChatRepository.pageSize;
      });
      _subscribe();
    }
  }

  void _onMessages(List<ChatMessage> msgs) {
    ChatMessage? newestIncoming;
    for (final m in msgs) {
      if (!m.isMine(_myId)) {
        newestIncoming = m;
        break;
      }
    }
    if (newestIncoming == null) return;
    final changed = newestIncoming.id != _lastIncomingId;
    _lastIncomingId = newestIncoming.id;
    if (changed && !newestIncoming.isRead) _scheduleMarkRead();
  }

  void _scheduleMarkRead() {
    if (_chatId == null) return;
    _readDebounce?.cancel();
    _readDebounce = Timer(const Duration(milliseconds: 500), _markRead);
  }

  Future<void> _markRead() async {
    final chatId = _chatId;
    if (chatId == null || !_resumed || !mounted) return;
    try {
      await _repo.markRead(chatId, _myId);
    } catch (e) {
      debugPrint('chat: markRead failed: $e');
    }
  }

  Future<void> _send() async {
    final chatId = _chatId;
    final text = _text.text.trim();
    if (chatId == null || text.isEmpty) return;
    final profile = Provider.of<ProfileProvider>(context, listen: false);
    final photo = profile.profileId;
    _text.clear();
    if (_scroll.hasClients && _scroll.offset > 0) {
      _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    }
    try {
      await _repo.sendText(
        chatId: chatId,
        fromId: _myId,
        fromName: widget.currentUserName,
        fromPhoto: (photo != null && photo.isNotEmpty) ? photo : null,
        toId: _otherId,
        toName: widget.chattingWithName,
        text: text,
      );
    } catch (e) {
      debugPrint('chat: send failed: $e');
      if (!mounted) return;
      if (_text.text.trim().isEmpty) {
        _text.text = text;
        _text.selection = TextSelection.collapsed(offset: text.length);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send your message. Please try again.")),
      );
    }
  }

  Future<void> _attach() async {
    final chatId = _chatId;
    if (chatId == null || _attaching) return;
    _focus.unfocus();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Photo library'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    final XFile? picked;
    try {
      // Downscaled + compressed on-device so uploads stay small.
      picked = await ImagePicker().pickImage(source: source, imageQuality: 70, maxWidth: 1600);
    } catch (e) {
      debugPrint('chat: image pick failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open your photos. Check the app's permissions.")),
      );
      return;
    }
    if (picked == null || !mounted) return;

    final photo = Provider.of<ProfileProvider>(context, listen: false).profileId;
    setState(() => _attaching = true);
    try {
      await _repo.sendImage(
        chatId: chatId,
        fromId: _myId,
        fromName: widget.currentUserName,
        fromPhoto: (photo != null && photo.isNotEmpty) ? photo : null,
        toId: _otherId,
        toName: widget.chattingWithName,
        file: File(picked.path),
      );
      if (_scroll.hasClients && _scroll.offset > 0) {
        _scroll.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    } catch (e) {
      debugPrint('chat: photo send failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send your photo. Please try again.")),
      );
    } finally {
      if (mounted) setState(() => _attaching = false);
    }
  }

  String get _firstName {
    final parts = widget.chattingWithName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty || parts.first.isEmpty ? 'them' : parts.first;
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _grouped(ChatMessage a, ChatMessage b) {
    if (a.fromId != b.fromId) return false;
    final ta = a.sentAt ?? DateTime.now();
    final tb = b.sentAt ?? DateTime.now();
    if (!_sameDay(ta, tb)) return false;
    return ta.difference(tb).abs() <= _groupWindow;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        titleSpacing: 0,
        title: Row(
          children: [
            ChatInitialsAvatar(name: widget.chattingWithName),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.chattingWithName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildBody(context)),
          ChatComposer(
            controller: _text,
            focusNode: _focus,
            enabled: _chatId != null,
            onSend: _send,
            onAttach: _attach,
            attaching: _attaching,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (_error != null && !_loaded) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off, size: 40, color: scheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                "Couldn't load this conversation.",
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _error = null);
                  if (_chatId == null) {
                    _init();
                  } else {
                    _subscribe();
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_chatId == null || !_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChatInitialsAvatar(name: widget.chattingWithName, radius: 36),
              const SizedBox(height: 16),
              Text(
                'Say hello to $_firstName 👋',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Your messages will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    final msgs = _messages;
    final showLoader = _hasMore && _loadingMore;
    return GestureDetector(
      onTap: () => _focus.unfocus(),
      child: ListView.builder(
        controller: _scroll,
        reverse: true,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        itemCount: msgs.length + (showLoader ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == msgs.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          }
          final m = msgs[i];
          // Newest first: i + 1 is the older (visually above) message.
          final older = i + 1 < msgs.length ? msgs[i + 1] : null;
          final newer = i > 0 ? msgs[i - 1] : null;
          final at = m.sentAt ?? DateTime.now();
          final newDay = older == null || !_sameDay(older.sentAt ?? DateTime.now(), at);
          final bubble = ChatBubble(
            key: ValueKey(m.id),
            message: m,
            isMine: m.isMine(_myId),
            groupedWithOlder: !newDay && _grouped(m, older),
            groupedWithNewer: newer != null && _grouped(m, newer),
          );
          if (!newDay) return bubble;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [ChatDaySeparator(day: at), bubble],
          );
        },
      ),
    );
  }
}
