import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'report_preview_screen.dart';
import '../../models/report_config.dart';

/// Report History Screen - View and manage past reports
class ReportHistoryScreen extends StatefulWidget {
  const ReportHistoryScreen({super.key});

  @override
  State<ReportHistoryScreen> createState() => _ReportHistoryScreenState();
}

class _ReportHistoryScreenState extends State<ReportHistoryScreen> {
  List<FileSystemEntity> _reportFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);

    try {
      final output = await getApplicationDocumentsDirectory();
      final reportsDir = Directory('${output.path}/reports');

      if (await reportsDir.exists()) {
        final files = reportsDir
            .listSync()
            .where((file) => file.path.endsWith('.pdf'))
            .toList();

        files.sort((a, b) {
          final aModified = File(a.path).lastModifiedSync();
          final bModified = File(b.path).lastModifiedSync();
          return bModified.compareTo(aModified);
        });

        setState(() {
          _reportFiles = files;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading reports: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reportFiles.isEmpty
              ? _buildEmptyState()
              : _buildReportList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No reports yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generate your first report to see it here',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportFiles.length,
      itemBuilder: (context, index) {
        final file = File(_reportFiles[index].path);
        return _buildReportCard(file);
      },
    );
  }

  Widget _buildReportCard(File file) {
    final stat = file.statSync();
    final modified = stat.modified;
    final size = stat.size;
    final fileName = file.path.split('/').last;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: const Icon(Icons.picture_as_pdf, color: Colors.red, size: 40),
        title: Text(
          fileName.replaceAll('report_', '').replaceAll('.pdf', ''),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Generated: ${DateFormat('MMM dd, yyyy HH:mm').format(modified)}'),
            Text('Size: ${(size / 1024).toStringAsFixed(1)} KB'),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'view',
              child: Row(
                children: [
                  Icon(Icons.visibility),
                  SizedBox(width: 8),
                  Text('View'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(Icons.share),
                  SizedBox(width: 8),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) => _handleMenuAction(value as String, file),
        ),
        onTap: () => _viewReport(file),
      ),
    );
  }

  void _handleMenuAction(String action, File file) {
    switch (action) {
      case 'view':
        _viewReport(file);
        break;
      case 'share':
        _shareReport(file);
        break;
      case 'delete':
        _deleteReport(file);
        break;
    }
  }

  void _viewReport(File file) {
    // Create a dummy config for preview
    final config = ReportConfig(
      id: file.path.split('/').last.replaceAll('report_', '').replaceAll('.pdf', ''),
      type: ReportType.detailed,
      periodType: ReportPeriodType.thisMonth,
      startDate: DateTime.now(),
      endDate: DateTime.now(),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportPreviewScreen(pdfFile: file, config: config),
      ),
    );
  }

  Future<void> _shareReport(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Expense Report',
        text: 'Here is my expense report from ExpenWall',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sharing report: $e')),
        );
      }
    }
  }

  Future<void> _deleteReport(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await file.delete();
        _loadReports();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Report deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting report: $e')),
          );
        }
      }
    }
  }
}
