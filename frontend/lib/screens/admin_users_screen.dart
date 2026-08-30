import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/app_colors.dart';
import '../providers/app_providers.dart';
import '../widgets/clinical_card.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  void _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final users = await ref.read(adminServiceProvider).getAdminUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _toggleStatus(UserModel u) async {
    try {
      final newStatus = !(u.isActive ?? true);
      await ref.read(adminServiceProvider).toggleUserStatus(u.id, newStatus);
      _fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User & Role Administration',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage hospital clinician accounts, assign RBAC permissions, and review security audit states.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),

            if (_loading)
              const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator()))
            else
              ClinicalCard(
                padding: EdgeInsets.zero,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: MaterialStateProperty.all(AppColors.primaryLight.withOpacity(0.5)),
                      headingTextStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 13),
                      dataTextStyle: TextStyle(fontSize: 13, color: AppColors.textPrimary),
                      columns: const [
                        DataColumn(label: Text('Clinician Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Specialty')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: _users.map((u) {
                        return DataRow(
                          cells: [
                            DataCell(Text(u.fullName, style: const TextStyle(fontWeight: FontWeight.w600))),
                            DataCell(Text(u.email)),
                            DataCell(
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(u.role, style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark, fontSize: 11)),
                              ),
                            ),
                            DataCell(Text(u.specialty ?? '')),
                            DataCell(
                              StatusBadge.success(label: (u.isActive ?? true) ? 'Active' : 'Inactive'),
                            ),
                            DataCell(
                              TextButton(
                                onPressed: () => _toggleStatus(u),
                                child: Text((u.isActive ?? true) ? 'Deactivate' : 'Activate', style: TextStyle(color: (u.isActive ?? true) ? AppColors.error : AppColors.success)),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
