import 'package:flutter/material.dart';
import '../theme.dart';
import '../api.dart';

class ChatScreen extends StatefulWidget {
  final String cnic, name;
  const ChatScreen({super.key, required this.cnic, required this.name});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _Msg {
  final String text;
  final bool isUser;
  _Msg(this.text, this.isUser);
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<_Msg> _msgs = [];
  bool _loading = false;

  String get _initials {
    final parts = widget.name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '?';
  }

  @override
  void initState() {
    super.initState();
    _msgs.add(_Msg(
      "Hello ${widget.name.split(' ').first} 👋  I'm your NEMRAS assistant. "
      "I can answer questions about your health record, medications, and lab results. "
      "All answers are grounded on your official NEMRAS record only.",
      false,
    ));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _msgs.add(_Msg(text, true));
      _loading = true;
      _ctrl.clear();
    });
    _scrollToBottom();
    try {
      final reply = await Api.chat(widget.cnic, text);
      if (mounted) setState(() => _msgs.add(_Msg(reply, false)));
    } catch (_) {
      if (mounted) {
        setState(() => _msgs
            .add(_Msg("I couldn't reach your record service right now.", false)));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _scrollToBottom();
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        titleSpacing: 16,
        title: Row(children: [
          // NEMRAS AI brand chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('NEMRAS AI',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 8),
          // Patient initials badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(_initials,
                style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 8),
          // Online + grounded status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.stable.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: AppTheme.stable, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              const Text('ONLINE · GROUNDED',
                  style: TextStyle(
                      color: AppTheme.stable,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4)),
            ]),
          ),
        ]),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            itemCount: _msgs.length,
            itemBuilder: (_, i) => _ChatBubble(msg: _msgs[i]),
          ),
        ),
        if (_loading) const _TypingIndicator(),
        _InputBar(ctrl: _ctrl, onSend: _send),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Chat bubble
// ─────────────────────────────────────────────────────────────
class _ChatBubble extends StatelessWidget {
  final _Msg msg;
  const _ChatBubble({required this.msg});

  @override
  Widget build(BuildContext context) => Align(
        alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.76),
          decoration: BoxDecoration(
            color: msg.isUser ? AppTheme.primary : AppTheme.surface,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
              bottomRight: Radius.circular(msg.isUser ? 4 : 18),
            ),
            border: msg.isUser
                ? null
                : Border.all(color: const Color(0xFFE2EAEC)),
          ),
          child: Text(msg.text,
              style: TextStyle(
                  color: msg.isUser ? Colors.white : AppTheme.ink,
                  fontSize: 14,
                  height: 1.45)),
        ),
      );
}

// ─────────────────────────────────────────────────────────────
// Typing indicator
// ─────────────────────────────────────────────────────────────
class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 20, bottom: 6),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2EAEC)),
            ),
            child: const Text('Assistant is typing…',
                style: TextStyle(color: AppTheme.muted, fontSize: 12)),
          ),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────
// Input bar
// ─────────────────────────────────────────────────────────────
class _InputBar extends StatelessWidget {
  final TextEditingController ctrl;
  final VoidCallback onSend;
  const _InputBar({required this.ctrl, required this.onSend});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          border: Border(top: BorderSide(color: Color(0xFFE8EAEC))),
        ),
        child: SafeArea(
          top: false,
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2EAEC)),
              ),
              child: const Icon(Icons.mic_outlined, color: AppTheme.muted, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: ctrl,
                onSubmitted: (_) => onSend(),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Ask anything about your health…',
                  hintStyle:
                      const TextStyle(color: AppTheme.muted, fontSize: 14),
                  filled: true,
                  fillColor: AppTheme.bg,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onSend,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      );
}
