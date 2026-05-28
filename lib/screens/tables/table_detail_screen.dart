import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../../providers/table_provider.dart';
import '../../models/models.dart';

/// Standalone screen (mobile navigation)
class TableDetailScreen extends StatelessWidget {
  final TableModel table;
  const TableDetailScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12121F),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          table.tableName,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.06)),
        ),
      ),
      body: TableDetailPanel(
        table: table,
        onDeleted: () => Navigator.pop(context),
      ),
    );
  }
}

/// Embeddable panel (desktop split panel)
class TableDetailPanel extends StatelessWidget {
  final TableModel table;
  final VoidCallback? onDeleted;

  const TableDetailPanel({super.key, required this.table, this.onDeleted});

  void _copyQrUrl(BuildContext context) {
    if (table.qrCodeData != null) {
      Clipboard.setData(ClipboardData(text: table.qrCodeData!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ QR URL copied to clipboard!')),
      );
    }
  }

  Future<void> _deleteTable(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Table',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        content: Text(
          'Delete "${table.tableName}"? This will also remove its QR code.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4757)),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<TableProvider>().deleteTable(table.id);
      if (context.mounted) onDeleted?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // QR Code
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF6B35).withOpacity(0.15),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: table.qrCodeData != null
                ? QrImageView(
                    data: table.qrCodeData!,
                    version: QrVersions.auto,
                    size: 220,
                    foregroundColor: const Color(0xFF1a1a2e),
                  )
                : const SizedBox(
                    width: 220,
                    height: 220,
                    child: Icon(Icons.qr_code_rounded,
                        size: 100, color: Colors.black38),
                  ),
          ),
          const SizedBox(height: 20),
          // Table info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                _infoRow('Table Number', 'Table ${table.tableNumber}'),
                const Divider(color: Colors.white10, height: 20),
                _infoRow('Table Name', table.tableName),
                const Divider(color: Colors.white10, height: 20),
                _infoRow(
                    'Status', table.isOccupied ? '🔴 Occupied' : '🟢 Free'),
                const Divider(color: Colors.white10, height: 20),
                _infoRow('Serviceable',
                    table.isServiceable ? '✅ Active' : '⛔ Inactive'),
                const Divider(color: Colors.white10, height: 20),
                // QR URL
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'QR URL',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _copyQrUrl(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF6B35).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                table.qrCodeData ?? 'N/A',
                                style: const TextStyle(
                                  color: Color(0xFFFF6B35),
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.copy_rounded,
                                color: Color(0xFFFF6B35), size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Serviceable toggle
          Consumer<TableProvider>(
            builder: (ctx, tp, _) {
              final currentTable =
                  tp.tables.firstWhere((t) => t.id == table.id,
                      orElse: () => table);
              return Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.power_settings_new_rounded,
                        color: Color(0xFFFF6B35), size: 20),
                    const SizedBox(width: 12),
                    const Text('Serviceable',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const Spacer(),
                    Switch(
                      value: currentTable.isServiceable,
                      onChanged: (val) =>
                          tp.toggleServiceable(table.id, val),
                      activeThumbColor: const Color(0xFFFF6B35),
                      activeTrackColor:
                          const Color(0xFFFF6B35).withOpacity(0.3),
                      inactiveThumbColor: Colors.white38,
                      inactiveTrackColor: Colors.white12,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Delete button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () => _deleteTable(context),
              icon: const Icon(Icons.delete_rounded, size: 16),
              label: const Text('Delete Table'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF4757),
                side: const BorderSide(color: Color(0xFFFF4757)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.5), fontSize: 13)),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ],
    );
  }
}
