class FileItem {
  final String filename;
  final String topic;
  final int chunks;

  FileItem({required this.filename, required this.topic, required this.chunks});

  factory FileItem.fromJson(Map<String, dynamic> json) => FileItem(
        filename: json['filename'] as String,
        topic: json['topic'] as String? ?? '',
        chunks: json['chunks'] as int? ?? 0,
      );
}
