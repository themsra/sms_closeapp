class FolderItem {
  final String id;
  final String name;
  final String? path;

  const FolderItem({
    required this.id,
    required this.name,
    this.path,
  });
}
