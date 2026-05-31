import 'package:flutter/material.dart';
import '../../models/absensi_model.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/constants.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({Key? key}) : super(key: key);

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  List<AbsensiModel> _absensiList = [];
  bool _isLoading = true;
  String _errorMsg = "";
  final _databaseService = RealtimeDatabaseService();

  // Dynamic statistics map for student summaries
  Map<String, Map<String, dynamic>> _rekapMahasiswa = {};

  @override
  void initState() {
    super.initState();
    _fetchLaporan();
  }

  Future<void> _fetchLaporan() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final list = await _databaseService.getAllAbsensi();

      // Calculate statistical summary per student
      Map<String, Map<String, dynamic>> rekap = {};
      for (var item in list) {
        final nim = item.nim ?? "-";
        if (!rekap.containsKey(nim)) {
          rekap[nim] = {
            "nama": item.nama ?? "N/A",
            "nim": nim,
            "hadir": 0,
            "sakit": 0,
            "izin": 0,
            "total": 0,
          };
        }

        final status = item.status.toLowerCase();
        if (status.contains("hadir")) rekap[nim]!["hadir"]++;
        if (status.contains("sakit")) rekap[nim]!["sakit"]++;
        if (status.contains("izin")) rekap[nim]!["izin"]++;
        rekap[nim]!["total"]++;
      }

      setState(() {
        _absensiList = list;
        _rekapMahasiswa = rekap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Gagal mengambil laporan dari Firebase Cloud.";
        _isLoading = false;
      });
    }
  }

  void _handlePrintReport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.print, color: AppConstants.primaryColor),
            SizedBox(width: 10),
            Text("Cetak Laporan"),
          ],
        ),
        content: const Text(
          "Fitur Ekspor Laporan: Sistem siap dihubungkan dengan pustaka PDF atau printer lokal untuk mencetak berkas rekapitulasi skripsi Anda.",
          style: TextStyle(color: AppConstants.textLight, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text("OK", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: AppConstants.primaryColor));
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline,
                  size: 60, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(_errorMsg, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor),
                onPressed: _fetchLaporan,
                child: const Text("Coba Lagi",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      );
    }

    final rekapList = _rekapMahasiswa.values.toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Rekapitulasi Kehadiran",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.secondaryColor,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                icon: const Icon(Icons.print, size: 18, color: Colors.white),
                label: const Text("Cetak PDF",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                onPressed: _handlePrintReport,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total Stats Info Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.01),
                    blurRadius: 10),
              ],
              border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                    "Total Mahasiswa", _rekapMahasiswa.length, Colors.blue),
                Container(width: 1, height: 40, color: Colors.grey[200]),
                _buildSummaryItem(
                    "Total Absensi", _absensiList.length, Colors.green),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Detail Table
          const Text(
            "Tabel Kehadiran Mahasiswa",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.textDark),
          ),
          const SizedBox(height: 12),

          rekapList.isEmpty
              ? const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Center(
                      child: Text(
                          "Belum ada data kehadiran untuk dibuat laporan."),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border:
                          Border.all(color: Colors.grey.withValues(alpha: 0.1)),
                    ),
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          AppConstants.primaryColor.withValues(alpha: 0.04)),
                      columns: const [
                        DataColumn(
                            label: Text("NAMA MAHASISWA",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text("NIM",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text("HADIR",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text("SAKIT",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text("IZIN",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                        DataColumn(
                            label: Text("TOTAL SIKAP",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12))),
                      ],
                      rows: rekapList.map((userRekap) {
                        return DataRow(
                          cells: [
                            DataCell(Text(userRekap["nama"],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold))),
                            DataCell(Text(userRekap["nim"])),
                            DataCell(Center(
                                child: Text("${userRekap["hadir"]}",
                                    style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold)))),
                            DataCell(Center(
                                child: Text("${userRekap["sakit"]}",
                                    style: const TextStyle(
                                        color: Colors.orange,
                                        fontWeight: FontWeight.bold)))),
                            DataCell(Center(
                                child: Text("${userRekap["izin"]}",
                                    style: const TextStyle(
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold)))),
                            DataCell(Center(
                                child: Text("${userRekap["total"]}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)))),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(label,
            style:
                const TextStyle(color: AppConstants.textLight, fontSize: 13)),
        const SizedBox(height: 6),
        Text(
          "$value",
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
