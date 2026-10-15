import 'package:flutter_test/flutter_test.dart';

import 'package:dx5veevents/services/chat/chat_repository.dart';

void main() {
  group('ChatRepository.canonicalChatId', () {
    test('orders numeric ids by value, not as strings', () {
      expect(ChatRepository.canonicalChatId('10', '9'), '9-10');
      expect(ChatRepository.canonicalChatId('9', '10'), '9-10');
    });

    test('is the same whichever side asks', () {
      expect(
        ChatRepository.canonicalChatId('123', '45'),
        ChatRepository.canonicalChatId('45', '123'),
      );
    });

    test('falls back to string order when an id is not numeric', () {
      expect(ChatRepository.canonicalChatId('b', 'a'), 'a-b');
      expect(ChatRepository.canonicalChatId('abc', '5'), '5-abc');
    });

    test('handles equal ids', () {
      expect(ChatRepository.canonicalChatId('7', '7'), '7-7');
    });
  });
}
