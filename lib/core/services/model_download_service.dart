import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:background_downloader/background_downloader.dart';

class ModelDownloadService {
  // The unique ID extracted from the provided Google Drive link
  static const String googleDriveFileId = '11Ceupy9_6b9GwCqCtUIIfIeAuOFbkmSC';
  static const String modelFileName = 'gemma3-1B-it-int4.task';

  static Future<String> getModelPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$modelFileName';
  }

  static Future<bool> isModelDownloaded() async {
    final path = await getModelPath();
    final file = File(path);
    if (await file.exists()) {
      final length = await file.length();
      if (length > 100 * 1024 * 1024) { // Must be larger than 100MB (Model is ~1.5GB)
        return true;
      } else {
        await file.delete(); // Delete corrupted or HTML warning files
      }
    }
    return false;
  }

  static Future<void> downloadModel({
    required Function(int received, int total) onProgress,
    required Function() onSuccess,
    required Function(String error) onError,
  }) async {
    try {
      final savePath = await getModelPath();
      final dio = Dio();
      final url =
          'https://docs.google.com/uc?export=download&id=$googleDriveFileId';

      // First request to get the warning page HTML
      var response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      String downloadUrl = url;
      final html = response.data.toString();

      // Extract the confirm token and uuid from the hidden form inputs
      final confirmRegex = RegExp(r'name="confirm"\s+value="([^"]+)"');
      final uuidRegex = RegExp(r'name="uuid"\s+value="([^"]+)"');

      final confirmMatch = confirmRegex.firstMatch(html);
      final uuidMatch = uuidRegex.firstMatch(html);

      if (confirmMatch != null && uuidMatch != null) {
        final confirmToken = confirmMatch.group(1);
        final uuid = uuidMatch.group(1);
        downloadUrl =
            'https://drive.usercontent.google.com/download?id=$googleDriveFileId&export=download&confirm=$confirmToken&uuid=$uuid';
      } else {
        // Fallback if parsing fails
        downloadUrl = '$url&confirm=t';
      }

      // Extract cookies from the response headers
      final cookies = response.headers.map['set-cookie'];
      String cookieHeader = '';
      if (cookies != null) {
        cookieHeader = cookies.join('; ');
      }

      // Configure notifications
      FileDownloader().configureNotification(
        running: const TaskNotification('Downloading AI Model', 'progress: {progress}%'),
        complete: const TaskNotification('Download Complete', 'The AI model is ready.'),
        error: const TaskNotification('Download Failed', 'Could not download the AI model.'),
        progressBar: true,
      );

      // Download the actual binary file using background_downloader
      final task = DownloadTask(
        url: downloadUrl,
        filename: modelFileName,
        baseDirectory: BaseDirectory.applicationDocuments,
        headers: cookieHeader.isNotEmpty ? {'Cookie': cookieHeader} : const {},
        updates: Updates.statusAndProgress,
        retries: 3,
        allowPause: true,
      );

      final result = await FileDownloader().download(
        task,
        onProgress: (progress) {
          if (progress >= 0.0 && progress <= 1.0) {
            onProgress((progress * 1000).toInt(), 1000);
          }
        },
      );

      if (result.status == TaskStatus.complete) {
        onSuccess();
      } else {
        onError('Download failed with status: ${result.status}');
      }
    } catch (e) {
      onError(e.toString());
    }
  }
}
