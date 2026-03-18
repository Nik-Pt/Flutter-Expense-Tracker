import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import '../models/transaction.dart';
import 'db_helper.dart';

class DataSyncService {

  static Future<void> exportToJSON() async {
    final transactions = await DBHelper.instance.getAllTransactions();
    final List<Map<String, dynamic>> jsonList = transactions.map((tx) => tx.toMap()).toList();
    final String jsonString = jsonEncode(jsonList);

    await _saveFileToDevice(utf8.encode(jsonString), 'expenses_export.json');
  }

  static Future<void> exportToCSV() async {
    final transactions = await DBHelper.instance.getAllTransactions();

    List<List<dynamic>> rows = [
      ['ID', 'Description', 'Amount', 'Date (ms)', 'Category']
    ];

    for (var tx in transactions) {
      rows.add([tx.id, tx.description, tx.amount, tx.date.millisecondsSinceEpoch, tx.category]);
    }

    String csvData = csv.encode(rows);
    await _saveFileToDevice(utf8.encode(csvData), 'expenses_export.csv');
  }

  static Future<void> exportToExcel() async {
    final transactions = await DBHelper.instance.getAllTransactions();
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Expenses'];
    excel.setDefaultSheet('Expenses');

    sheetObject.appendRow([
      TextCellValue('ID'), TextCellValue('Description'),
      TextCellValue('Amount'), TextCellValue('Date'), TextCellValue('Category')
    ]);

    for (var tx in transactions) {
      sheetObject.appendRow([
        IntCellValue(tx.id ?? 0),
        TextCellValue(tx.description),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.date.toIso8601String()),
        TextCellValue(tx.category),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/expenses_export.xlsx');
    await file.writeAsBytes(excel.encode()!);
    await _saveFileToDevice(excel.encode()!, 'expenses_export.xlsx');
  }

  //Helper to save text-based files (CSV/JSON) and share them
  static Future<void> _saveFileToDevice(List<int> bytes, String fileName) async {
    try {
      //file_picker requires a Uint8List, so we convert it here
      final Uint8List dataBytes = Uint8List.fromList(bytes);

      //Pass the bytes directly into the saveFile method!
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Expense Export',
        fileName: fileName,
        bytes: dataBytes,
      );
      if (outputFile != null) {
        print("File successfully saved to: $outputFile");
      } else {
        print("User canceled the save process.");
      }
    } catch (e) {
      print("Error saving file: $e");
    }
  }

  static Future<void> importFromJSON() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['json']
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String jsonString = await file.readAsString();
      List<dynamic> jsonList = jsonDecode(jsonString);

      for (var item in jsonList) {
        item['id'] = null;
        await DBHelper.instance.create(Transaction.fromMap(item));
      }
    }
  }

  static Future<void> importFromCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['csv']
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final String csvString = await file.readAsString();

      List<List<dynamic>> rows = csv.decode(csvString);

      for (int i = 1; i < rows.length; i++) {
        var row = rows[i];
        if (row.length < 5) continue;

        String description = row[1].toString();
        double amount = double.tryParse(row[2].toString()) ?? 0.0;
        int dateMs = int.tryParse(row[3].toString()) ?? DateTime.now().millisecondsSinceEpoch;
        String category = row[4].toString();

        final style = Transaction.getCategoryStyle(category);
        final tx = Transaction(
          description: description,
          amount: amount,
          date: DateTime.fromMillisecondsSinceEpoch(dateMs),
          category: category,
          icon: style['icon'],
          color: style['color'],
        );

        await DBHelper.instance.create(tx);
      }
    }
  }

  static Future<void> importFromExcel() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom, allowedExtensions: ['xlsx']
    );

    if (result != null) {
      var bytes = File(result.files.single.path!).readAsBytesSync();
      var excel = Excel.decodeBytes(bytes);

      for (var table in excel.tables.keys) {
        var sheet = excel.tables[table]!;

        for (int i = 1; i < sheet.rows.length; i++) {
          var row = sheet.rows[i];
          if (row.length < 5) continue;

          String description = row[1]?.value?.toString() ?? '';
          double amount = double.tryParse(row[2]?.value?.toString() ?? '0') ?? 0.0;

          String dateStr = row[3]?.value?.toString() ?? '';
          DateTime date = DateTime.tryParse(dateStr) ?? DateTime.now();

          String category = row[4]?.value?.toString() ?? 'Other';

          final style = Transaction.getCategoryStyle(category);

          final tx = Transaction(
            description: description,
            amount: amount,
            date: date,
            category: category,
            icon: style['icon'],
            color: style['color'],
          );

          await DBHelper.instance.create(tx);
        }
      }
    }
  }
}