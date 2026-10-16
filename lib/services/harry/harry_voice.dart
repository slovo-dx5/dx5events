import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin wrapper around speech-to-text (mic → text) and text-to-speech (spoken
/// replies) for Harry. Microphone permission is requested by
/// [SpeechToText.initialize] the first time [ensureReady] runs.
class HarryVoice {
  final SpeechToText _stt = SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _sttReady = false;

  bool get isListening => _stt.isListening;

  Future<bool> ensureReady() async {
    if (_sttReady) return true;
    _sttReady = await _stt.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _sttReady;
  }

  /// Starts listening. [onPartial] fires as words are recognised; [onFinal]
  /// fires once with the completed transcript. Returns false if the mic is
  /// unavailable or permission was denied.
  Future<bool> startListening({
    required void Function(String text) onPartial,
    required void Function(String text) onFinal,
  }) async {
    if (!await ensureReady()) return false;
    await _stt.listen(
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (result) {
        if (result.finalResult) {
          onFinal(result.recognizedWords);
        } else {
          onPartial(result.recognizedWords);
        }
      },
    );
    return true;
  }

  Future<void> stopListening() => _stt.stop();

  Future<void> speak(String text) async {
    await _tts.stop();
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  Future<void> stopSpeaking() => _tts.stop();
}
