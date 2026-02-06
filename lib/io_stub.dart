class File {
  File(String path);
  Future<File> copy(String newPath) => throw UnsupportedError('File not supported on web');
}
