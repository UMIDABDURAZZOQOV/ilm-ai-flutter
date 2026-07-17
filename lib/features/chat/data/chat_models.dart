class ChatMessage {
  final String role; // 'user' | 'assistant'
  final String content;
  final List<String>? citations;

  ChatMessage({required this.role, required this.content, this.citations});

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        role: json['role'] as String,
        content: json['content'] as String,
        citations: (json['citations'] as List?)?.map((e) => e.toString()).toList(),
      );
}

class ChatAskResponse {
  final String answer;
  final List<String> citations;

  ChatAskResponse({required this.answer, required this.citations});

  factory ChatAskResponse.fromJson(Map<String, dynamic> json) => ChatAskResponse(
        answer: json['answer'] as String? ?? '',
        citations: (json['citations'] as List? ?? []).map((e) => e.toString()).toList(),
      );
}
