import 'package:photo_manager/photo_manager.dart';

import '../../models/file_item.dart';

class MediaService {
  Future<bool> requestPermission() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.hasAccess;
  }

  Future<List<FileItem>> getRecentMedia({int page = 0, int size = 60}) async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.isAuth && !permission.hasAccess) return [];

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      onlyAll: true,
    );
    if (albums.isEmpty) return [];

    final assets = await albums.first.getAssetListPaged(page: page, size: size);
    final result = <FileItem>[];
    for (final asset in assets) {
      final fileSize = await asset.fileSize;

      result.add(FileItem(
        id: asset.id,
        name: asset.title ?? 'media_${asset.id}',
        type: asset.type == AssetType.video ? 'video/*' : 'image/*',
        size: fileSize,
        modifiedAt: asset.modifiedDateTime,
      ));
    }
    return result;
  }

  Future<AssetEntity?> findAsset(String id) async {
    return AssetEntity.fromId(id);
  }
}
