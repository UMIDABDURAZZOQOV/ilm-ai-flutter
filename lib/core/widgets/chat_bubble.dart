import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class ChatBubble extends StatelessWidget {
  final bool isUser;
  final String content;
  final List<String>? citations;
  final ThemeColors colors;

  const ChatBubble({super.key, required this.isUser, required this.content, this.citations, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isUser ? LinearGradient(colors: [colors.primary, colors.secondary]) : null,
          color: isUser ? null : colors.card,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isUser ? null : Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: TextStyle(color: isUser ? Colors.white : colors.text, fontSize: 14.5, height: 1.4)),
            if (citations != null && citations!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: citations!
                    .map((c) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(c, style: TextStyle(fontSize: 11, color: isUser ? Colors.white : colors.textSecondary)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: isUser ? 0.15 : -0.15, end: 0, curve: Curves.easeOutCubic);
  }
}
