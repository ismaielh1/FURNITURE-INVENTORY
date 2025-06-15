import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:furniture_inventory/providers/inventory_controller.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';

class UpdateScreen extends StatefulWidget {
  const UpdateScreen({super.key});

  @override
  State<UpdateScreen> createState() => _UpdateScreenState();
}

class _UpdateScreenState extends State<UpdateScreen> {
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String _statusText = 'تحميل التحديث';

  Future<void> _startDownload(String downloadUrl) async {
    bool installPermissionOk = false;
    if (Platform.isAndroid) {
      final status =
          await Permission.requestInstallPackages.request();
      installPermissionOk = status.isGranted;
    }
    if (!installPermissionOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('يجب السماح بصلاحية تثبيت التطبيقات')),
        );
      }
      return;
    }

    bool storagePermissionOk = false;
    if (Platform.isAndroid) {
      final deviceInfo = await DeviceInfoPlugin().androidInfo;
      if (deviceInfo.version.sdkInt >= 30) {
        final storageStatus =
            await Permission.manageExternalStorage.request();
        storagePermissionOk = storageStatus.isGranted;
      } else {
        final storageStatus = await Permission.storage.request();
        storagePermissionOk = storageStatus.isGranted;
      }
    } else {
      storagePermissionOk = true;
    }

    if (!storagePermissionOk) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content:
                  Text('يجب السماح بصلاحية الوصول للتخزين')),
        );
      }
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final List<Directory>? dirs =
          await getExternalStorageDirectories(
              type: StorageDirectory.downloads);
      if (dirs == null || dirs.isEmpty) {
        throw Exception("لا يمكن الوصول لمجلد التحميلات");
      }
      final Directory dir = dirs.first;
      final filePath = '${dir.path}/app-update.apk';

      await Dio().download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1 && mounted) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _statusText = 'اكتمل التحميل، جاري الفتح...';
        });
      }

      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done) {
        throw Exception(
            'Could not open the file: ${result.message}');
      }
    } catch (e) {
      print('Download/Install Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'فشل تحميل أو فتح التحديث: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0.0;
          _statusText = 'تحميل التحديث';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<InventoryProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل التحديث'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('الإصدار الجديد المتاح:',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                    Text(
                      provider.latestVersion ?? "غير متوفر",
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary),
                    ),
                    const SizedBox(height: 24),
                    Text('ملاحظات الإصدار:',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium),
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      provider.updateNotes ??
                          'لا توجد ملاحظات مسجلة.',
                      style:
                          Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (provider.downloadUrl != null &&
                provider.downloadUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 20.0),
                child: ElevatedButton.icon(
                  icon: _isDownloading
                      ? const SizedBox.shrink()
                      : const Icon(
                          Icons.download_for_offline_outlined),
                  label: _isDownloading
                      ? SizedBox(
                          height: 24,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              LinearProgressIndicator(
                                  value: _downloadProgress,
                                  minHeight: 24,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                  backgroundColor:
                                      Colors.white24,
                                  valueColor:
                                      const AlwaysStoppedAnimation<
                                              Color>(
                                          Colors.white54)),
                              Text(
                                '${(_downloadProgress * 100).toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold),
                              )
                            ],
                          ),
                        )
                      : Text(_statusText),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    textStyle: const TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold),
                  ),
                  onPressed: _isDownloading
                      ? null
                      : () =>
                          _startDownload(provider.downloadUrl!),
                ),
              )
          ],
        ),
      ),
    );
  }
}
