# In-app chat (1:1)

## How it fits together

| Piece | Where |
|---|---|
| Data contract (models, Firestore paths) | `lib/services/chat/chat_models.dart` |
| All reads/writes | `lib/services/chat/chat_repository.dart` |
| Inbox ("Messages") + tab badge | `lib/screens/chats/all_chats.dart`, `widgets/inbox_*.dart` |
| Conversation | `lib/screens/chats/chat_screen.dart` (`CioChatScreen`), `widgets/chat_*.dart` |
| Summaries + push | `functions/chat_messages.js` (`onChatMessageCreated`) |
| Notification tap | `lib/main.dart`: `targetPage == 'chat'` → `/chat?with=<id>&name=<name>` |

**Firestore**

- `messages/{chatId}/{chatId}/{messageId}`: unchanged from the old chat, so existing threads and older app builds keep working.
- `chats/{chatId}`: per-conversation summary (`participants`, `names`, `photos`, `lastMessage`, `updatedAt`, `unread.{userId}`, `recentIds`).
  - Written by the Cloud Function when a message is created.
  - The app only ever sets its own `unread.{myId}` back to 0.
- `users/{id}/contacts/{otherId}`: the legacy inbox. The function keeps it updated so old app builds still list conversations.

Message `type` is 0 for text and 1 for a photo. A photo's `content` is its Directus asset URL (`<Baseurl>/assets/<fileId>`); `ChatRepository.sendImage` uploads to Directus `/files` first. Older builds already render type 1 as an image.

New threads use the id `<lower>-<higher>` (numeric). Old threads were keyed by `String.hashCode` order, so `resolveChatId` looks for an existing thread under both orders first.

**Push**

- The function sends the push with the Admin SDK. Fields: `targetPage: chat`, `chatWith`, `chatWithName`, `chatId`. Android channel: `chat_messages`, registered in `main.dart`.
- The old client-side push used the legacy FCM HTTP API. That API was shut down in 2024, so it no longer worked.

## Rollout

1. **Deploy the function:**
   ```
   firebase deploy --only functions:onChatMessageCreated --project dx5ve-events
   ```
2. **Firestore rules.** They aren't in this repo, so check them in the console. Signed-in users need:
   - read on `chats` docs where they are in `participants`;
   - update of only `unread.<their id>` on those docs;
   - the existing read/write on `messages`.
3. **Ship the app build.**

Older threads are not backfilled: a conversation gets its summary, and so
appears in the new inbox, when its next message is sent.

## Tests

- `cd functions && npm test`: pure helpers of the Cloud Function.
- `flutter test test/chat_repository_test.dart`: chat id rule.
