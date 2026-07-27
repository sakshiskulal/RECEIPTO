import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:receipto/core/constants/constants.dart';
import 'package:receipto/core/widgets/glass_card.dart';
import 'package:receipto/core/widgets/nebula_background.dart';
import 'package:receipto/features/ai_assistant/domain/models/chat_message_model.dart';
import 'package:receipto/features/ai_assistant/data/services/ai_assistant_service.dart';

class AIAssistantScreen extends ConsumerStatefulWidget {
  const AIAssistantScreen({super.key});

  @override
  ConsumerState<AIAssistantScreen> createState() => _AIAssistantScreenState();
}

class _AIAssistantScreenState extends ConsumerState<AIAssistantScreen> with TickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  final List<String> _suggestions = [
    'Is my laptop under warranty?',
    'Show products expiring this month.',
    'How much did I spend this year?',
    'Which receipt is the largest?',
  ];

  @override
  void initState() {
    super.initState();
    // Add default greeting
    _messages.add(
      ChatMessage(
        text: "Hello! I am your Receipto AI Assistant. Ask me anything about your receipts, warranties, purchases, categories, or overall expenses!",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, timestamp: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final service = ref.read(aiAssistantServiceProvider);
      final response = await service.ask(text);

      setState(() {
        _messages.add(ChatMessage(text: response, isUser: false, timestamp: DateTime.now()));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(
          ChatMessage(
            text: "Sorry, I encountered an issue processing your request. Please try again.",
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.onSurface, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'AI Warranty Assistant',
          style: GoogleFonts.hankenGrotesk(
            color: AppColors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.onSurface),
            onPressed: () {
              setState(() {
                _messages.clear();
                _messages.add(
                  ChatMessage(
                    text: "Chat history cleared. How can I help you today?",
                    isUser: false,
                    timestamp: DateTime.now(),
                  ),
                );
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Premium Nebula Background
          const Positioned.fill(
            child: AnimatedNebulaBackground(opacity: 0.8),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      return _buildChatBubble(msg, textTheme);
                    },
                  ),
                ),

                if (_isLoading) _buildTypingIndicator(),

                // Suggested chips if list is short or just welcome message
                if (_messages.length <= 2 && !_isLoading) _buildSuggestions(),

                _buildInputBar(textTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(ChatMessage msg, TextTheme textTheme) {
    final isUser = msg.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser) ...[
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
              ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: GlassCard(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                backgroundColor: isUser 
                    ? AppColors.primary.withValues(alpha: 0.15) 
                    : AppColors.cardSurface.withValues(alpha: 0.4),
                child: MarkdownText(
                  text: msg.text,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
              ),
            ),
            if (isUser) ...[
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
                child: const Icon(Icons.person_outline, color: AppColors.secondary, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 16),
            ),
            const SizedBox(width: 8),
            const TypingIndicatorDots(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      height: 48,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _suggestions.length,
        itemBuilder: (context, index) {
          final text = _suggestions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ActionChip(
              label: Text(text),
              labelStyle: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => _sendMessage(text),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: GlassCard(
              borderRadius: BorderRadius.circular(24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              child: TextField(
                controller: _textController,
                style: (textTheme.bodyMedium ?? const TextStyle()).copyWith(color: AppColors.onSurface),
                decoration: const InputDecoration(
                  hintText: 'Type your message...',
                  hintStyle: TextStyle(color: AppColors.onSurfaceVariant),
                  border: InputBorder.none,
                ),
                onSubmitted: _sendMessage,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white, size: 20),
              onPressed: () => _sendMessage(_textController.text),
            ),
          ),
        ],
      ),
    );
  }
}

class TypingIndicatorDots extends StatefulWidget {
  const TypingIndicatorDots({super.key});

  @override
  State<TypingIndicatorDots> createState() => _TypingIndicatorDotsState();
}

class _TypingIndicatorDotsState extends State<TypingIndicatorDots> with TickerProviderStateMixin {
  late AnimationController _controller;
  final List<Animation<double>> _animations = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    for (int i = 0; i < 3; i++) {
      final start = 0.2 * i;
      final end = start + 0.6;
      _animations.add(
        Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(start, end, curve: Curves.easeInOut),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final val = _animations[index].value;
              final double scale = 1.0 + (0.3 * math.sin(val * math.pi));
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3.0),
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withValues(alpha: 0.3 + (0.7 * math.sin(val * math.pi))),
                ),
                transform: Matrix4.diagonal3Values(scale, scale, 1.0),
              );
            },
          );
        }),
      ),
    );
  }
}

class MarkdownText extends StatelessWidget {
  final String text;
  final TextStyle? style;

  const MarkdownText({super.key, required this.text, this.style});

  @override
  Widget build(BuildContext context) {
    final lines = text.split('\n');
    final List<Widget> spans = [];

    for (final line in lines) {
      if (line.trim().startsWith('* ') || line.trim().startsWith('- ')) {
        final content = line.substring(line.indexOf(' ') + 1);
        spans.add(
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4.0, bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                Expanded(
                  child: RichText(
                    text: _parseBoldText(content, style),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        spans.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: RichText(
              text: _parseBoldText(line, style),
            ),
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: spans,
    );
  }

  TextSpan _parseBoldText(String text, TextStyle? baseStyle) {
    final parts = text.split('**');
    final List<TextSpan> children = [];
    bool isBold = false;

    for (final part in parts) {
      children.add(
        TextSpan(
          text: part,
          style: isBold
              ? (baseStyle ?? const TextStyle()).copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)
              : baseStyle,
        ),
      );
      isBold = !isBold;
    }

    return TextSpan(children: children);
  }
}
