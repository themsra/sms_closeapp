import 'package:flutter/material.dart';

import '../controllers/file_controller.dart';
import '../models/file_item.dart';

class StorageScreen extends StatefulWidget {
  const StorageScreen({super.key});

  @override
  State<StorageScreen> createState() => _StorageScreenState();
}

class _StorageScreenState extends State<StorageScreen> {
  final controller = FileController();
  List<FileItem> media = [];
  bool loading = false;

  Future<void> loadMedia() async {
    setState(() => loading = true);
    final result = await controller.recentMedia();
    if (!mounted) return;
    setState(() {
      media = result;
      loading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    loadMedia();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('گالری و فایل‌ها')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadMedia,
              child: media.isEmpty
                  ? ListView(children: const [SizedBox(height: 180), Center(child: Text('فایلی برای نمایش پیدا نشد'))])
                  : GridView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: media.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (_, index) {
                        final item = media[index];
                        return Card(
                          child: Center(
                            child: Icon(item.isVideo ? Icons.videocam : Icons.image, size: 34),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
