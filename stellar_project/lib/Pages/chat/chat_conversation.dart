import 'package:flutter/material.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/message_model.dart';
import 'services/chat_service.dart';

class ChatConversationPage extends StatefulWidget {
  final String conversationId;
  final String initialTitle;

  const ChatConversationPage({
    super.key,
    required this.conversationId,
    required this.initialTitle,
  });

  @override
  State<ChatConversationPage> createState() => _ChatConversationPageState();
}

class _ChatConversationPageState extends State<ChatConversationPage> {
  late final ChatService _service;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isInitialized = false;
  bool _isStreaming = false;
  String _streamingContent = '';
  ChatSession? _session;

  // Tracks current title so it can update live after first message
  late String _currentTitle;
  bool _titleSet = false;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.initialTitle;
    _titleSet = widget.initialTitle != 'New Chat';
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _service = ChatService(uid: uid);
    _initialize();
  }

  Future<void> _initialize() async {
    // Load existing messages first so history is passed to the AI session
    final messages = await _service.getMessages(widget.conversationId).first;
    final model = await _service.buildModel();

    // Rebuild Vertex AI chat history from stored messages
    final history = messages.map((m) {
      if (m.role == 'user') return Content.text(m.content);
      return Content('model', [TextPart(m.content)]);
    }).toList();

    if (!mounted) return;
    setState(() {
      _messages = messages;
      _session = model.startChat(history: history);
      _isInitialized = true;
    });
    _scrollToBottom();
  }

  Future<void> _send() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isStreaming || !_isInitialized || _session == null) return;

    _inputController.clear();

    final userMsg = await _service.saveMessage(widget.conversationId, 'user', text);
    setState(() {
      _messages.add(userMsg);
      _isStreaming = true;
      _streamingContent = '';
    });
    _scrollToBottom();

    // Auto-title the conversation from the first user message
    if (!_titleSet) {
      _titleSet = true;
      final newTitle = text.length > 45 ? '${text.substring(0, 45)}...' : text;
      setState(() => _currentTitle = newTitle);
      _service.updateConversation(widget.conversationId, title: newTitle);
    }

    try {
      final stream = _session!.sendMessageStream(Content.text(text));
      final buffer = StringBuffer();

      await for (final chunk in stream) {
        buffer.write(chunk.text ?? '');
        if (mounted) {
          setState(() => _streamingContent = buffer.toString());
          _scrollToBottom();
        }
      }

      final fullResponse = buffer.toString();
      final aiMsg = await _service.saveMessage(widget.conversationId, 'model', fullResponse);

      final preview = fullResponse.length > 60
          ? '${fullResponse.substring(0, 60)}...'
          : fullResponse;
      await _service.updateConversation(
        widget.conversationId,
        lastMessage: preview,
      );

      if (mounted) {
        setState(() {
          _messages.add(aiMsg);
          _isStreaming = false;
          _streamingContent = '';
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isStreaming = false;
          _streamingContent = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Something went wrong: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _currentTitle == 'New Chat' ? 'AI Chat' : _currentTitle,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? _buildMessageList(colorScheme)
                : const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
          ),
          _buildInputBar(colorScheme),
        ],
      ),
    );
  }

  Widget _buildMessageList(ColorScheme colorScheme) {
    final itemCount = _messages.length + (_isStreaming ? 1 : 0);

    if (_messages.isEmpty && !_isStreaming) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome,
                size: 52,
                color: Colors.white.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Text(
                'Ask me about your schedule, study plans,\nor anything academic.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == _messages.length && _isStreaming) {
          return _buildAiBubble(_streamingContent, isStreaming: true);
        }
        final msg = _messages[index];
        return msg.role == 'user'
            ? _buildUserBubble(msg.content, colorScheme)
            : _buildAiBubble(msg.content);
      },
    );
  }

  Widget _buildUserBubble(String text, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(4),
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              height: 1.45,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiBubble(String text, {bool isStreaming = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(18),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: text.isEmpty && isStreaming
              ? _buildTypingDots()
              : Text(
                  text,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    height: 1.45,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildTypingDots() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildInputBar(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: TextField(
                controller: _inputController,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                maxLines: 5,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isStreaming ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _isStreaming
                    ? colorScheme.primary.withValues(alpha: 0.45)
                    : colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isStreaming ? Icons.more_horiz : Icons.send_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
