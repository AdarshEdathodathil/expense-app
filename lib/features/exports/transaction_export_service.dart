import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:expense_tracker/features/transactions/domain/expense_transaction.dart';
import 'package:expense_tracker/core/currency/currency_option.dart';
import 'package:intl/intl.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

class TransactionExportService {
  static final _dateFormat = DateFormat('yyyy-MM-dd');

  static Future<void> shareCsv(List<ExpenseTransaction> transactions) async {
    final rows = <List<Object?>>[
      ['Date', 'Type', 'Category', 'Title', 'Amount', 'Currency', 'Added by'],
      ...transactions.map(
        (transaction) => [
          _dateFormat.format(transaction.transactionDate),
          transaction.type.name,
          transaction.category,
          transaction.note,
          (transaction.amountMinor / 100).toStringAsFixed(2),
          transaction.currency,
          transaction.createdByName,
        ],
      ),
    ];
    final csv = Csv().encode(rows);
    final file = XFile.fromData(
      Uint8List.fromList(utf8.encode(csv)),
      mimeType: 'text/csv',
      name: 'trace-transactions.csv',
    );
    await SharePlus.instance.share(
      ShareParams(
        files: [file],
        fileNameOverrides: const ['trace-transactions.csv'],
        text: 'Trace transactions export',
      ),
    );
  }

  static Future<void> sharePdf(List<ExpenseTransaction> transactions) async {
    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            'Trace — Transactions',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 6),
          pw.Text('Leave no expense untraced.'),
          pw.SizedBox(height: 18),
          pw.TableHelper.fromTextArray(
            headers: const ['Date', 'Type', 'Category', 'Title', 'Amount'],
            data: transactions
                .map(
                  (transaction) => [
                    _dateFormat.format(transaction.transactionDate),
                    transaction.type.name,
                    transaction.category,
                    transaction.note,
                    '${currencyOption(transaction.currency).symbol}${(transaction.amountMinor / 100).toStringAsFixed(2)}',
                  ],
                )
                .toList(),
          ),
        ],
      ),
    );
    await Printing.sharePdf(
      bytes: await document.save(),
      filename: 'trace-transactions.pdf',
    );
  }
}
