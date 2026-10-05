import 'package:file_picker/file_picker.dart';

import '../../models/file_item.dart';
import '../../models/folder_item.dart';

/// File access is intentionally based on Android's user-selected document
/// access rather than assuming unrestricted access to the whole filesystem.
class FileService {
  Future<List<FolderItem>> pickFolder() async {
    final path = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'انتخاب پوشه',
    );
    if (path == null) return [];

    final name = path.split(RegExp(r'[/\\]')).where((e) => e.isNotEmpty).last;
    return [FolderItem(id: path, name: name, path: path)];
  }

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: false);
    return result?.files.single;
  }

  FileItem fromPlatformFile(PlatformFile file) {
    return FileItem(
      id: file.identifier ?? file.path ?? file.name,
      name: file.name,
      path: file.path,
      size: file.size,
      type: 'application/octet-stream',
    );
  }
}
