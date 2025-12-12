import 'dart:io';

class ImageFormatValidator {
  static const Set<String> _supportedFormats = {'jpg', 'jpeg', 'png'};

  static bool isValidFormat(File file) {
    final String extension = _getFileExtension(file.path);
    return _supportedFormats.contains(extension);
  }

  static String _getFileExtension(String filePath) {
    if (filePath.isEmpty) {
      return '';
    }
    return filePath.split('.').last.toLowerCase();
  }

  static Set<String> get supportedFormats => _supportedFormats;
}
