import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageLocationException implements Exception {
  static const message =
      r"Don't found database location drive (without C:\) so, can't store your necessary record";

  @override
  String toString() => message;
}

class RecordsStorage {
  Directory? _cachedDirectory;

  String _fileName(String section) =>
      section.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_') + '.csv';

  Future<Directory> _ensureDirectory() async {
    final cached = _cachedDirectory;
    if (cached != null && await _isWritable(cached)) return cached;

    if (Platform.isWindows) {
      // D: is the required first choice. If it is missing or not writable,
      // try E: through Z:. C: is deliberately never considered.
      for (var code = 68; code <= 90; code++) {
        final drive = String.fromCharCode(code);
        final directory = Directory(drive + r':\SOFTLAND');
        try {
          await directory.create(recursive: true);
          if (await _isWritable(directory)) {
            _cachedDirectory = directory;
            return directory;
          }
        } catch (_) {
          // Try the next non-C drive.
        }
      }
      throw StorageLocationException();
    }

    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      documents.path + Platform.pathSeparator + 'SOFTLAND',
    );
    await directory.create(recursive: true);
    _cachedDirectory = directory;
    return directory;
  }

  Future<bool> _isWritable(Directory directory) async {
    try {
      await directory.create(recursive: true);
      final probe = File(
        directory.path + Platform.pathSeparator +
        '.softland_write_test_' +
        DateTime.now().microsecondsSinceEpoch.toString() + '.tmp',
      );
      await probe.writeAsString('SOFTLAND', flush: true);
      await probe.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, List<Map<String, String>>>> load(
    Map<String, List<String>> schemas,
  ) async {
    final directory = await _ensureDirectory();
    final result = <String, List<Map<String, String>>>{};
    final existingFiles = <String>{};

    for (final entry in schemas.entries) {
      final file = File(
        directory.path + Platform.pathSeparator + _fileName(entry.key),
      );
      if (await file.exists()) {
        existingFiles.add(entry.key);
        final contents = await file.readAsString();
        result[entry.key] = _decode(contents);
      } else {
        result[entry.key] = [];
      }
    }

    // One-time migration from the original SharedPreferences JSON store.
    // After migration, business records are read and written as section CSVs.
    final preferences = await SharedPreferences.getInstance();
    final legacyJson = preferences.getString('softland_records');
    if (legacyJson != null) {
      final decoded = jsonDecode(legacyJson) as Map<String, dynamic>;
      var migrated = false;
      for (final entry in schemas.entries) {
        if (existingFiles.contains(entry.key)) continue;
        final legacyRows = decoded[entry.key];
        if (legacyRows is List) {
          result[entry.key] = legacyRows.map(_legacyRecord).toList();
          migrated = true;
        }
      }
      if (migrated || existingFiles.isEmpty) {
        await save(result, schemas, directory: directory);
        await preferences.remove('softland_records');
      }
    }

    for (final section in schemas.keys) {
      result.putIfAbsent(section, () => []);
    }
    return result;
  }

  Map<String, String> _legacyRecord(dynamic value) {
    if (value is! Map) return <String, String>{};
    final map = Map<String, dynamic>.from(value);
    if (map['values'] is Map) {
      return Map<String, String>.from(
        (map['values'] as Map).map(
          (key, fieldValue) => MapEntry(
            key.toString(),
            fieldValue?.toString() ?? '',
          ),
        ),
      );
    }
    return {
      'Title / Reference': map['name']?.toString() ?? '',
      'Date / Period': map['date']?.toString() ?? '',
      'Details': map['details']?.toString() ?? '',
      'Amount': map['amount']?.toString() ?? '',
    };
  }

  List<Map<String, String>> _decode(String contents) {
    if (contents.trim().isEmpty) return [];
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
    ).convert(contents);
    if (rows.isEmpty) return [];

    final headers = rows.first.map((value) => value.toString()).toList();
    return rows.skip(1).where((row) {
      return row.any((value) => value.toString().isNotEmpty);
    }).map((row) {
      return <String, String>{
        for (var i = 0; i < headers.length; i++)
          headers[i]: i < row.length ? row[i].toString() : '',
      };
    }).toList();
  }

  Future<void> save(
    Map<String, List<Map<String, String>>> records,
    Map<String, List<String>> schemas, {
    Directory? directory,
  }) async {
    final target = directory ?? await _ensureDirectory();
    await target.create(recursive: true);

    for (final entry in schemas.entries) {
      final headers = entry.value;
      final rows = <List<dynamic>>[
        headers,
        for (final record in records[entry.key] ?? [])
          headers.map((field) => record[field] ?? '').toList(),
      ];
      final csvText = const ListToCsvConverter().convert(rows);
      final file = File(
        target.path + Platform.pathSeparator + _fileName(entry.key),
      );
      await file.writeAsString(csvText, flush: true);
    }
  }
}
