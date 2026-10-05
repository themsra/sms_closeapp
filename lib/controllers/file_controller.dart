import '../models/file_item.dart';
import '../services/storage/file_service.dart';
import '../services/storage/media_service.dart';

class FileController {
  final MediaService mediaService;
  final FileService fileService;

  FileController({
    MediaService? mediaService,
    FileService? fileService,
  })  : mediaService = mediaService ?? MediaService(),
        fileService = fileService ?? FileService();

  Future<List<FileItem>> recentMedia() => mediaService.getRecentMedia();
}
