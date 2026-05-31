import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../services/realtime_database_service.dart';
import '../../utils/constants.dart';

class DataUserScreen extends StatefulWidget {
  const DataUserScreen({Key? key}) : super(key: key);

  @override
  State<DataUserScreen> createState() => _DataUserScreenState();
}

class _DataUserScreenState extends State<DataUserScreen> {
  List<UserModel> _userList = [];
  List<UserModel> _filteredUserList = [];
  bool _isLoading = true;
  String _errorMsg = "";
  final _databaseService = RealtimeDatabaseService();
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUsers();
    _searchController.addListener(_filterUsers);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final data = await _databaseService.getUsers();
      setState(() {
        _userList = data;
        _filteredUserList = _userList;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMsg = "Gagal mengambil data user dari Firebase Cloud.";
        _isLoading = false;
      });
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredUserList = _userList.where((user) {
        return user.nama.toLowerCase().contains(query) ||
            (user.nim != null && user.nim!.toLowerCase().contains(query)) ||
            user.email.toLowerCase().contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search Header Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Cari nama, NIM, atau email...",
              prefixIcon: const Icon(
                Icons.search,
                color: AppConstants.secondaryColor,
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppConstants.secondaryColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),

        Expanded(child: _buildContent()),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppConstants.primaryColor),
      );
    }

    if (_errorMsg.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Text(_errorMsg, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                ),
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text(
                  "Coba Lagi",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredUserList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: AppConstants.textLight),
            const SizedBox(height: 16),
            Text(
              "Mahasiswa tidak ditemukan.",
              style: TextStyle(
                color: AppConstants.textLight,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchUsers,
      color: AppConstants.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _filteredUserList.length,
        itemBuilder: (context, index) {
          final user = _filteredUserList[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
            color: Colors.white,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.withOpacity(0.1)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundColor: AppConstants.primaryColor.withOpacity(0.08),
                  child: const Icon(
                    Icons.person,
                    color: AppConstants.primaryColor,
                  ),
                ),
                title: Text(
                  user.nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppConstants.textDark,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      "NIM: ${user.nim ?? '-'}",
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Email: ${user.email}",
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppConstants.textLight,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "MHS",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
