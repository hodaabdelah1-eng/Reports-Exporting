 import 'package:flutter/material.dart';
import '../repositories/report_repository.dart';
import '../services/report_service.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:excel/excel.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
class CustomerReportScreen extends StatefulWidget {
  const CustomerReportScreen({super.key});
  @override
  State<CustomerReportScreen> createState() =>
      _CustomerReportScreenState();
}
class _CustomerReportScreenState
    extends State<CustomerReportScreen> {
  final repo = ReportRepository();
  final service = ReportService();
  List<Map<String, dynamic>> reportData = [];
  String selectedCustomer = "Ahmed";
  final List<String> customers = [
    "Ahmed",
    "Ali",
    "Sara",
  ];
  @override
  void initState() {
    super.initState();
    loadData();
  }
  Future<void> loadData() async {
    final transactions =
        await repo.getTransactionsByCustomer(
      selectedCustomer,
    );
    final report =
        service.buildCustomerStatement(
      transactions,
    );
    setState(() {
      reportData = report;
    });
  }
  void onCustomerChanged(String? value) {
    if (value == null) return;
    setState(() {
      selectedCustomer = value;
    });
    loadData();
  }
  Future<void> exportPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (context) {
          return pw.Column(
            crossAxisAlignment:
                pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "Customer Report",
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight:
                      pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Table.fromTextArray(
                headers: [
                  "Date",
                  "Description",
                  "Debit",
                  "Credit",
                  "Balance",
                ],
                data: reportData.map((row) {
                  return [
                    row["date"].toString(),
                    row["description"].toString(),
                    row["debit"].toString(),
                    row["credit"].toString(),
                    row["balance"].toString(),
                  ];
                }).toList(),
              ),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) async =>
          pdf.save(),
    );
  }
  Future<void> exportExcel() async {
    try {
      var excel = Excel.createExcel();
      Sheet sheet = excel['Report'];

      sheet.appendRow([
        "Date",
        "Description",
        "Debit",
        "Credit",
        "Balance",
      ]);

      for (var row in reportData) {

        sheet.appendRow([
          row["date"].toString(),
          row["description"].toString(),
          row["debit"].toString(),
          row["credit"].toString(),
          row["balance"].toString(),
        ]);
      }

      final dir =
          await getApplicationDocumentsDirectory();

      final file = File(
        "${dir.path}/customer_report.xlsx",
      );

      final bytes = excel.encode();

      if (bytes == null) return;

      await file.writeAsBytes(bytes);

      await OpenFile.open(file.path);

      if (mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          const SnackBar(
            content:
                Text("Excel Exported Successfully"),
          ),
        );
      }

    } catch (e) {

      print(e);

      if (mounted) {

        ScaffoldMessenger.of(context)
            .showSnackBar(

          SnackBar(
            content: Text(
              "Export Error: $e",
            ),
          ),
        );
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {

    double totalDebit = 0;
    double totalCredit = 0;

    for (var row in reportData) {

      totalDebit += row["debit"];
      totalCredit += row["credit"];
    }

    double balance =
        totalDebit - totalCredit;

    return Scaffold(

      backgroundColor:
          const Color(0xffF5F7FA),

      appBar: AppBar(

        elevation: 0,

        backgroundColor:
            const Color(0xff1E3A5F),

        title: const Text(
          "Customer Report",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [

          IconButton(
            onPressed: exportPDF,
            icon: const Icon(
              Icons.picture_as_pdf,
            ),
          ),

          IconButton(
            onPressed: exportExcel,
            icon: const Icon(
              Icons.table_chart,
            ),
          ),
        ],
      ),

      body: Padding(

        padding:
            const EdgeInsets.all(16),

        child: Column(

          children: [

            // ================= HEADER =================

            Container(

              width: double.infinity,

              padding:
                  const EdgeInsets.all(20),

              decoration: BoxDecoration(

                color:
                    Colors.white,

                borderRadius:
                    BorderRadius.circular(16),

                boxShadow: [

                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                  ),
                ],
              ),

              child: Column(

                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [

                  const Text(

                    "Financial Customer Statement",

                    style: TextStyle(
                      fontSize: 22,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 15),

                  DropdownButtonFormField<String>(

                    value: selectedCustomer,

                    decoration:
                        InputDecoration(

                      labelText:
                          "Select Customer",

                      border:
                          OutlineInputBorder(

                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),

                    items:
                        customers.map((customer) {

                      return DropdownMenuItem(

                        value: customer,

                        child: Text(customer),
                      );

                    }).toList(),

                    onChanged:
                        onCustomerChanged,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ================= SUMMARY =================

            Row(

              children: [

                Expanded(
                  child: buildSummaryCard(
                    "Debit",
                    totalDebit.toString(),
                    Colors.green,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: buildSummaryCard(
                    "Credit",
                    totalCredit.toString(),
                    Colors.red,
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: buildSummaryCard(
                    "Balance",
                    balance.toString(),
                    Colors.blue,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ================= TABLE =================

            Expanded(

              child: Container(

                width: double.infinity,

                padding:
                    const EdgeInsets.all(16),

                decoration: BoxDecoration(

                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(16),

                  boxShadow: [

                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                    ),
                  ],
                ),

                child: SingleChildScrollView(

                  scrollDirection:
                      Axis.horizontal,

                  child: DataTable(

                    headingRowColor:
                        WidgetStateProperty.all(
                      const Color(0xff1E3A5F),
                    ),

                    headingTextStyle:
                        const TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                    ),

                    columns: const [

                      DataColumn(
                        label: Text("#"),
                      ),

                      DataColumn(
                        label: Text("Date"),
                      ),

                      DataColumn(
                        label: Text("Description"),
                      ),

                      DataColumn(
                        label: Text("Debit"),
                      ),

                      DataColumn(
                        label: Text("Credit"),
                      ),

                      DataColumn(
                        label: Text("Balance"),
                      ),
                    ],

                    rows:
                        List.generate(

                      reportData.length,

                      (index) {

                        final row =
                            reportData[index];

                        return DataRow(

                          cells: [

                            DataCell(
                              Text(
                                "${index + 1}",
                              ),
                            ),

                            DataCell(
                              Text(
                                row["date"]
                                    .toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                row["description"]
                                    .toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                row["debit"]
                                    .toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                row["credit"]
                                    .toString(),
                              ),
                            ),

                            DataCell(
                              Text(
                                row["balance"]
                                    .toString(),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildSummaryCard(

    String title,
    String value,
    Color color,

  ) {

    return Container(

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(

        color: Colors.white,

        borderRadius:
            BorderRadius.circular(16),

        boxShadow: [

          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          ),
        ],
      ),

      child: Column(

        children: [

          Text(

            title,

            style: TextStyle(
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(

            value,

            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}