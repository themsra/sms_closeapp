import 'package:photo_manager/photo_manager.dart';

class PermissionService {
  Future<bool> requestPhotos() async {
    final result = await PhotoManager.requestPermissionExtend();
    return result.isAuth || result.hasAccess;
  }
}
