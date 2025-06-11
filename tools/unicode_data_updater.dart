import 'dart:io';
import 'package:path/path.dart' as path;

/// Base URL for Unicode data files
const String unicodeBaseUrl = 'https://www.unicode.org/Public/UCD/latest/ucd';

/// List of files to download
const List<String> filesToDownload = [
  'CompositionExclusions.txt',
  'NormalizationTest.txt',
  'UnicodeData.txt',
];

/// Directory to store downloaded files
const String dataDir = './data';

/// Downloads a file from a URL and saves it to the specified path
Future<void> downloadFile(String url, String savePath) async {
  final client = HttpClient();

  print('Downloading $url...');

  try {
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to download file. Status code: ${response.statusCode}');
    }

    final file = File(savePath);
    final sink = file.openWrite();

    await response.pipe(sink);
    await sink.flush();
    await sink.close();

    print('Successfully downloaded to $savePath');
  } catch (e) {
    print('Error downloading $url: $e');
    rethrow;
  } finally {
    client.close();
  }
}

/// Ensures the data directory exists
Future<void> ensureDirectoryExists(String dir) async {
  final directory = Directory(dir);
  if (!await directory.exists()) {
    await directory.create(recursive: true);
    print('Created directory: $dir');
  }
}

Future<void> main() async {
  print('Starting Unicode data update...');

  // Ensure data directory exists
  await ensureDirectoryExists(dataDir);

  // Download each file
  for (final fileName in filesToDownload) {
    final fileUrl = '$unicodeBaseUrl/$fileName';
    final savePath = path.join(dataDir, fileName);

    await downloadFile(fileUrl, savePath);
  }

  print('\nUnicode data update completed successfully!');
  print('All files have been saved to the $dataDir directory.');
  print('\nTo generate normalization data, run:');
  print('dart run tools/normalizer_gen.dart');
}
