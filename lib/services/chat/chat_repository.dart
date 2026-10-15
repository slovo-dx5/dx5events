import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'chat_models.dart';

export 'chat_models.dart';

/// All chat reads and writes. Screens never touch Firestore directly.
///
/// CONTRACT — the public API below is shared by the inbox and conversation
/// screens. Implement the bodies; don't change the signatures.
class ChatRepository {
  ChatRepository._();

  static final ChatRepository instance = ChatRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Messages per page in a conversation.
  static const int pageSize = 40;

  /// Firestore caps a batch at 500 writes; stay well under it.
  static const int _batchLimit = 450;

  /// Resolved chat ids per user pair. A thread's id never changes once it
  /// exists, so this only costs memory. Holding the future (not the result)
  /// also collapses concurrent lookups for the same pair into one.
  final Map<String, Future<String>> _chatIdCache = {};

  /// "<lower>-<higher>" for two user ids, comparing numerically when both
  /// parse as ints (so "9" sorts before "10") and as strings otherwise. This
  /// is the id of every new thread, whichever side opens it.
  @visibleForTesting
  static String canonicalChatId(String a, String b) {
    final ai = int.tryParse(a);
    final bi = int.tryParse(b);
    final cmp = (ai != null && bi != null) ? ai.compareTo(bi) : a.compareTo(b);
    return cmp <= 0 ? '$a-$b' : '$b-$a';
  }

  /// The conversation id for two user ids. Returns the id of an existing
  /// thread if there is one (legacy threads were keyed "a-b" or "b-a"
  /// depending on String.hashCode), otherwise "<lower>-<higher>" by numeric
  /// value.
  Future<String> resolveChatId(String myId, String otherId) {
    if (myId == otherId) return Future.value('$myId-$myId');
    final key = canonicalChatId(myId, otherId);
    final cached = _chatIdCache[key];
    if (cached != null) return cached;
    final future = _lookupChatId(myId, otherId).catchError((Object e) {
      // Offline or denied: fall back to the canonical id, but don't remember
      // the guess so the next open looks again.
      debugPrint('ChatRepository.resolveChatId $key: $e');
      _chatIdCache.remove(key);
      return key;
    });
    _chatIdCache[key] = future;
    return future;
  }

  Future<String> _lookupChatId(String myId, String otherId) async {
    final candidates = ['$myId-$otherId', '$otherId-$myId'];

    // A summary doc means the Cloud Function has seen this thread already.
    for (final id in candidates) {
      final summary = await _db.collection('chats').doc(id).get();
      if (summary.exists) return id;
    }

    // Older threads predate `chats/`, so only their messages give them away.
    for (final id in candidates) {
      final messages =
          await _db.collection('messages').doc(id).collection(id).limit(1).get();
      if (messages.docs.isNotEmpty) return id;
    }

    return canonicalChatId(myId, otherId);
  }

  Query<Map<String, dynamic>> _inboxQuery(String myId) =>
      _db.collection('chats').where('participants', arrayContains: myId);

  /// The user's conversations, newest activity first (sorted on the device,
  /// so no composite index is needed).
  Stream<List<ChatSummary>> watchInbox(String myId) {
    return _inboxQuery(myId).snapshots().map((snap) {
      final rows = snap.docs.map((d) => ChatSummary.fromDoc(d, myId)).toList();
      rows.sort((a, b) {
        final at = a.updatedAt;
        final bt = b.updatedAt;
        if (at == null && bt == null) return 0;
        if (at == null) return 1;
        if (bt == null) return -1;
        return bt.compareTo(at);
      });
      return rows;
    });
  }

  /// Sum of the user's unread counts across conversations (Inbox tab badge).
  Stream<int> watchUnreadTotal(String myId) {
    return _inboxQuery(myId)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ChatSummary.fromDoc(d, myId).unread)
            .fold<int>(0, (total, n) => total + n))
        .distinct();
  }

  /// [myId]'s unread count on one conversation. The open chat screen watches
  /// this because the Cloud Function can bump the count just after the screen
  /// marked the new message read.
  Stream<int> watchUnread(String chatId, String myId) {
    return _db
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) => ((doc.data()?['unread'] as Map?)?[myId] as num?)?.toInt() ?? 0)
        .distinct();
  }

  /// Newest [limit] messages, newest first (for a reversed ListView).
  ///
  /// Metadata changes are included so a sent message flips from pending to
  /// confirmed. A just-sent message has no server timestamp yet, but the
  /// local cache orders it by an estimate, so it still lands on top.
  Stream<List<ChatMessage>> watchMessages(String chatId, {int limit = pageSize}) {
    return _db
        .collection('messages')
        .doc(chatId)
        .collection(chatId)
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots(includeMetadataChanges: true)
        .map((snap) => snap.docs.map(ChatMessage.fromDoc).toList());
  }

  /// Sends a text message. Trims [text]; does nothing if it is empty. The
  /// Cloud Function updates `chats/{chatId}` and sends the push.
  Future<void> sendText({
    required String chatId,
    required String fromId,
    required String fromName,
    String? fromPhoto,
    required String toId,
    required String toName,
    required String text,
  }) async {
    final content = text.trim();
    if (content.isEmpty) return;

    // Legacy ids were the bare millis; the sender suffix keeps two devices
    // sending in the same millisecond from overwriting each other. Ordering
    // always uses `timestamp`, never the id.
    final messageId = '${DateTime.now().millisecondsSinceEpoch}_$fromId';
    final data = <String, dynamic>{
      'idFrom': fromId,
      'idTo': toId,
      'content': content,
      'type': 0,
      'timestamp': FieldValue.serverTimestamp(),
      'isread': false,
      'sentFrom': fromName,
      'sentTo': toName,
      if (fromPhoto != null && fromPhoto.isNotEmpty) 'fromPhoto': fromPhoto,
    };
    await _db
        .collection('messages')
        .doc(chatId)
        .collection(chatId)
        .doc(messageId)
        .set(data);
  }

  /// Marks the other person's messages to [myId] as read and clears
  /// `chats/{chatId}.unread.<myId>`.
  ///
  /// Best effort: failures are logged, never thrown, because the screen calls
  /// this as a side effect of being open.
  Future<void> markRead(String chatId, String myId) async {
    try {
      // Two equality filters only, so Firestore needs no composite index.
      final unread = await _db
          .collection('messages')
          .doc(chatId)
          .collection(chatId)
          .where('idTo', isEqualTo: myId)
          .where('isread', isEqualTo: false)
          .get();

      final docs = unread.docs;
      for (var i = 0; i < docs.length; i += _batchLimit) {
        final batch = _db.batch();
        final end = i + _batchLimit < docs.length ? i + _batchLimit : docs.length;
        for (final doc in docs.sublist(i, end)) {
          batch.update(doc.reference, {'isread': true});
        }
        await batch.commit();
      }
    } catch (e) {
      debugPrint('ChatRepository.markRead messages $chatId: $e');
    }

    // Cleared even if the messages step failed: the badge is what users see.
    // `update`, not a merge-set, so a thread the Cloud Function hasn't
    // summarised yet doesn't get a stray doc with no participants.
    try {
      await _db.collection('chats').doc(chatId).update({'unread.$myId': 0});
    } on FirebaseException catch (e) {
      if (e.code != 'not-found') debugPrint('ChatRepository.markRead unread $chatId: $e');
    } catch (e) {
      debugPrint('ChatRepository.markRead unread $chatId: $e');
    }
  }
}
