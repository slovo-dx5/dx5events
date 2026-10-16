import 'package:cloud_firestore/cloud_firestore.dart';

/// Firestore layout for 1:1 chat (see docs/features/chat.md).
///
/// Messages stay where they always were, so existing threads and older app
/// builds keep working:
///   messages/{chatId}/{chatId}/{messageId}
///     idFrom, idTo (user ids as strings), content, type (0 = text,
///     1 = photo: content is the image URL),
///     timestamp (server), isread, sentFrom, sentTo (display names),
///     fromPhoto (optional Directus file id of the sender's photo)
///
/// New summary doc per conversation, written by the `onChatMessageCreated`
/// Cloud Function (never by the app, except clearing its own unread count):
///   chats/{chatId}
///     participants: [idA, idB]
///     names: {id: display name}, photos: {id: file id}
///     lastMessage: {text, from, type, at}
///     updatedAt (timestamp), unread: {id: int}
class ChatMessage {
  final String id;
  final String fromId;
  final String toId;
  final String text;
  final int type;

  /// Null while a just-sent message waits for the server timestamp.
  final DateTime? sentAt;
  final bool isRead;

  /// True for a local write the server hasn't confirmed yet.
  final bool pending;

  const ChatMessage({
    required this.id,
    required this.fromId,
    required this.toId,
    required this.text,
    required this.type,
    required this.sentAt,
    required this.isRead,
    required this.pending,
  });

  bool isMine(String myId) => fromId == myId;

  factory ChatMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? const {};
    final ts = d['timestamp'];
    return ChatMessage(
      id: doc.id,
      fromId: '${d['idFrom'] ?? ''}',
      toId: '${d['idTo'] ?? ''}',
      text: '${d['content'] ?? ''}',
      type: d['type'] is int ? d['type'] as int : 0,
      sentAt: ts is Timestamp ? ts.toDate() : null,
      isRead: d['isread'] == true,
      pending: doc.metadata.hasPendingWrites,
    );
  }
}

/// One row of the inbox, from `chats/{chatId}`, seen from [myId]'s side.
class ChatSummary {
  final String chatId;
  final String myId;
  final String otherId;
  final String otherName;

  /// Directus file id of the other person's photo, if known.
  final String? otherPhoto;
  final String lastText;

  /// [ChatMessage.type] of the last message (0 = text, 1 = photo).
  final int lastType;
  final String lastFromId;
  final DateTime? updatedAt;
  final int unread;

  const ChatSummary({
    required this.chatId,
    required this.myId,
    required this.otherId,
    required this.otherName,
    required this.otherPhoto,
    required this.lastText,
    required this.lastType,
    required this.lastFromId,
    required this.updatedAt,
    required this.unread,
  });

  bool get lastIsMine => lastFromId == myId;

  factory ChatSummary.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, String myId) {
    final d = doc.data() ?? const {};
    final participants = (d['participants'] as List? ?? const []).map((e) => '$e').toList();
    final otherId = participants.firstWhere((p) => p != myId, orElse: () => myId);
    final names = Map<String, dynamic>.from(d['names'] as Map? ?? const {});
    final photos = Map<String, dynamic>.from(d['photos'] as Map? ?? const {});
    final last = Map<String, dynamic>.from(d['lastMessage'] as Map? ?? const {});
    final unread = Map<String, dynamic>.from(d['unread'] as Map? ?? const {});
    final at = d['updatedAt'];
    final photo = photos[otherId];
    return ChatSummary(
      chatId: doc.id,
      myId: myId,
      otherId: otherId,
      otherName: '${names[otherId] ?? 'Delegate'}',
      otherPhoto: photo is String && photo.isNotEmpty ? photo : null,
      lastText: '${last['text'] ?? ''}',
      lastType: (last['type'] as num?)?.toInt() ?? 0,
      lastFromId: '${last['from'] ?? ''}',
      updatedAt: at is Timestamp ? at.toDate() : null,
      unread: (unread[myId] as num?)?.toInt() ?? 0,
    );
  }
}
