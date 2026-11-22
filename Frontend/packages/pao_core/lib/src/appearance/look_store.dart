import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

/// Where the app keeps its cached look between launches, so illustrations
/// replaced by an admin show offline too.
abstract interface class LookStore {
  /// The file named [name], or null.
  Future<Uint8List?> read(String name);

  /// Writes [bytes] as [name].
  Future<void> write(String name, List<int> bytes);
}

/// [LookStore] in a folder; [FileLookStore.support] uses the app's support
/// directory.
class FileLookStore implements LookStore {
  /// Creates the store in [folder].
  FileLookStore(this.folder);

  /// The store in `<app support>/look`.
  static Future<FileLookStore> support() async => FileLookStore(
    Directory('${(await getApplicationSupportDirectory()).path}/look'),
  );

  /// The folder holding the files.
  final Directory folder;

  @override
  Future<Uint8List?> read(String name) async {
    final file = File('${folder.path}/$name');
    return file.existsSync() ? await file.readAsBytes() : null;
  }

  @override
  Future<void> write(String name, List<int> bytes) async {
    await folder.create(recursive: true);
    await File('${folder.path}/$name').writeAsBytes(bytes, flush: true);
  }
}

/// [LookStore] in memory, for tests and platforms without files.
class MemoryLookStore implements LookStore {
  /// The stored files by name.
  final files = <String, Uint8List>{};

  @override
  Future<Uint8List?> read(String name) async => files[name];

  @override
  Future<void> write(String name, List<int> bytes) async =>
      files[name] = Uint8List.fromList(bytes);
}
