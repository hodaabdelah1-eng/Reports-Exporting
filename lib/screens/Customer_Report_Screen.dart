 import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';
import '../services/report_service.dart';
import 'package:flutter_application_1/utils/excel_generator.dart;
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
class CustomerReportScreen extends StatefulWidget {
  
  @override
  State<CustomerReportScreen> createState() => _CustomerReportScreenState();


class _CustomerReportScreenState extends State<CustomerReportScreen> {

  final repo = ReportRepository();
  final service = ReportService();

  List<Map<String, dynamic>> reportData = [];

  String selectedCustomer = "Ahmed";

  List<String> customers = ["Ahmed", "Ali", "Sara"];

  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    var transactions = await repo.getTransactionsByCustomer(selectedCustomer);
    var report = service.buildCustomerStatement(transactions);

    setState(() {
      reportData = report;
    });
  }

  void onCustomerChanged(String? value) {
    setState(() {
      selectedCustomer = value!;
    });
    loadData();
  }

  // 📄 PDF Export
  void exportPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            children: reportData.map((row) {
              return pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(row["date"].toString()),
                  pw.Text(row["description"].toString()),
                  pw.Text(row["debit"].toString()),
                  pw.Text(row["credit"].toString()),
                  pw.Text(row["balance"].toString()),
                ],
              );
            }).toList(),
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }
  // 📊 Excel Export (direct method)
        void exportExcel() async {
  print(" CLICK WORKS");
  try {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Report'];

    sheet.appendRow(["Date","Description","Debit","Credit","Balance"]);

    for (var row in reportData) {
      sheet.appendRow([
        row["date"].toString(),
        row["description"].toString(),
        row["debit"].toString(),
        row["credit"].toString(),
        row["balance"].toString(),
      ]);
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File("${dir.path}/report.xlsx");

    final bytes = excel.encode();

    if (bytes == null) {
      print("❌ encoding failed");
      return;
    }

    await file.writeAsBytes(bytes);

    print("✅ Saved: ${file.path}");

    // 🔥 دي أهم سطر
    await OpenFile.open(file.path);

  } catch (e) {
    print("❌ ERROR: $e");
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Customer Report"),
        actions: [
          IconButton(
            icon: Icon(Icons.picture_as_pdf),
            onPressed: exportPDF,
          ),
          IconButton(
            icon: Icon(Icons.table_chart),
            onPressed: exportExcel,
          ),
        ],
      ),

      body: Column(
        children: [

           
          // Dropdown
          Padding(
            padding: const EdgeInsets.all(10),
            child: DropdownButton<String>(
              value: selectedCustomer,
              isExpanded: true,
              items: customers.map((customer) {
                return DropdownMenuItem(
                  value: customer,
                  child: Text(customer),
                );
              }).toList(),
              onChanged: onCustomerChanged,
            ),
          ),

          // Table
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Date")),
                  DataColumn(label: Text("Description")),
                  DataColumn(label: Text("Debit")),
                  DataColumn(label: Text("Credit")),
                  DataColumn(label: Text("Balance")),
                ],
                rows: reportData.map((row) {
                  return DataRow(cells: [
                    DataCell(Text(row["date"].toString())),
                    DataCell(Text(row["description"].toString())),
                    DataCell(Text(row["debit"].toString())),
                    DataCell(Text(row["credit"].toString())),
                    DataCell(Text(row["balance"].toString())),
                  ]);
                }).toList(),
              ),
            ),
          ),

        ],
      ),
    );
  }
}