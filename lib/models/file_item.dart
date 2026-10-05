class FileItem {
  final String id;
  final String name;
  final String? path;
  final int size;
  final String type;
  final DateTime? modifiedAt;

  const FileItem({
    required this.id,
    required this.name,
    this.path,
    required this.size,
    required this.type,
    this.modifiedAt,
  });

  bool get isImage => type.startsWith('image/');
  bool get isVideo => type.startsWith('video/');
}
