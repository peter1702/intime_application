import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'dart:io';

class Files {
  
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _getFile(String fileName) async {
    final path = await _localPath;
    return File('$path/$fileName');
  }

  static Future<int> writeToFile(String fileName, String data) async {
    try {
      final file = await _getFile(fileName);
      file.writeAsString(data);
      return 0;
    } catch (error) {
      print('>>> File error: $error');
      return 1;
    }  
  }

  static Future<int> deleteFile(String fileName) async {
    try {
      final file = await _getFile(fileName);
      file.delete();
      return 0;
    } catch (error) {
      print('>>> File error: $error');
      return 1;
    }  
  }

  static Future<String> readFromFile(fileName) async {
    try {
      final file = await _getFile(fileName);
      // Read the file.
      String content = await file.readAsString();
      return content;
    } catch (error) {
      print('>>> File error: $error');
      return '';
    }
  }

  static Future<void> directoryList() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> fileEntities; 
    fileEntities = directory.listSync(recursive: true, followLinks: false);
    for (FileSystemEntity entity in fileEntities) {
      print(entity.toString());
    }
  }

}
