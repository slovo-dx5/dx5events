import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';

import '../../constants.dart';
import '../../providers/harry_controller.dart';
import '../../services/harry/harry_voice.dart';
import 'harry_message.dart';

/// The expanded chat surface for Harry. Hand-rolled bubble list (reusing the
/// app's existing chat bubble colours) + an input row with text, mic and send.
class HarryChatPanel extends StatefulWidget {
  const HarryChatPanel({Key? key, required this.onClose}) : super(key: key);

  final VoidCallback onClose;

  @override
  State<HarryChatPanel> createState() => _HarryChatPanelState();
}

class _HarryChatPanelState extends State<HarryChatPanel> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final HarryVoice _voice = HarryVoice();
  bool _listening = false;

  @override
  void initState() {
    super.initState();
    // Let the controller speak replies through our TTS engine.
    context.read<HarryController>().speakHandler = _voice.speak;
  }

  @override
  void dispose() {
    _voice.stopListening();
    _voice.stopSpeaking();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send([String? override]) async {
    final text = (override ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    await context.read<HarryController>().sendUserMessage(text);
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _voice.stopListening();
      setState(() => _listening = false);
      return;
    }
    final started = await _voice.startListening(
      onPartial: (t) => _input.text = t,
      onFinal: (t) {
        _input.text = t;
        setState(() => _listening = false);
        if (t.trim().isNotEmpty) _send(t);
      },
    );
    if (started) {
      setState(() => _listening = true);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Microphone unavailable. Check permissions.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<HarryController>();
    _scrollToBottom();

    final media = MediaQuery.of(context);
    final height = media.size.height * 0.62;
    final width = media.size.width - 24;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: width > 420 ? 420 : width,
        height: height,
        decoration: BoxDecoration(
          color: kLightAppbar,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            _header(controller),
            Expanded(
              child: ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                itemCount: controller.messages.length,
                itemBuilder: (_, i) => _bubble(controller.messages[i]),
              ),
            ),
            _inputRow(controller),
          ],
        ),
      ),
    );
  }

  Widget _header(HarryController controller) {
    return Container(
      color: kConnectedBlue,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Colors.white,
            backgroundImage: AssetImage('assets/images/harry_hare.jpg'),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Harry',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: controller.speakReplies ? 'Mute replies' : 'Speak replies',
            icon: Icon(
              controller.speakReplies ? Icons.volume_up : Icons.volume_off,
              color: Colors.white,
            ),
            onPressed: controller.toggleSpeak,
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _bubble(HarryMessage m) {
    if (m.isTool) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 34,
              height: 14,
              child: SpinKitThreeBounce(color: kConnectedBlue, size: 10),
            ),
            const SizedBox(width: 8),
            Text(m.toolLabel ?? 'Working…',
                style: TextStyle(
                    color: kTextColorGrey,
                    fontSize: 12,
                    fontStyle: FontStyle.italic)),
          ],
        ),
      );
    }

    final isUser = m.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isUser ? kRightBubble : kLeftBubble,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 2),
            bottomRight: Radius.circular(isUser ? 2 : 14),
          ),
        ),
        child: m.text.isEmpty && m.isStreaming
            ? const SpinKitThreeBounce(color: kConnectedBlue, size: 14)
            : Text(m.text,
                style: const TextStyle(color: kLightBoldText, fontSize: 14)),
      ),
    );
  }

  Widget _inputRow(HarryController controller) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 10),
      color: kLightCardColor,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(_listening ? Icons.mic : Icons.mic_none,
                  color: _listening ? kConnectedRed : kConnectedBlue),
              onPressed: _toggleMic,
            ),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: _listening ? 'Listening…' : 'Ask Harry…',
                  filled: true,
                  fillColor: kScaffoldColor,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            CircleAvatar(
              backgroundColor: controller.isBusy ? kDarkBold : kConnectedBlue,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: controller.isBusy ? null : () => _send(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
