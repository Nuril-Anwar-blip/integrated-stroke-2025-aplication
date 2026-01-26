import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../modules/medication_reminder/models/medication_reminder.dart';

class MedicationChecklistCard extends StatelessWidget {
  final List<MedicationReminder> reminders;
  final Function(MedicationReminder) onToggle;

  const MedicationChecklistCard({
    super.key,
    required this.reminders,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final todayReminders = reminders.where((r) => !r.taken).toList();
    final completedCount = reminders.where((r) => r.taken).length;
    final totalCount = reminders.length;

    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_liquid_rounded,
                  color: Colors.teal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Checklist Obat Hari Ini',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (totalCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$completedCount/$totalCount',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.teal,
                    ),
                  ),
                ),
            ],
          ),
          if (todayReminders.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...todayReminders.take(3).map((reminder) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MedicationItem(
                  reminder: reminder,
                  onToggle: () => onToggle(reminder),
                  isDark: isDark,
                ),
              );
            }),
            if (todayReminders.length > 3)
              TextButton(
                onPressed: () {
                  // Navigate to medication reminder screen
                },
                child: Text(
                  'Lihat ${todayReminders.length - 3} lainnya',
                  style: TextStyle(color: theme.primaryColor),
                ),
              ),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Semua obat sudah diminum hari ini! 🎉',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MedicationItem extends StatelessWidget {
  final MedicationReminder reminder;
  final VoidCallback onToggle;
  final bool isDark;

  const _MedicationItem({
    required this.reminder,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: reminder.taken
                ? Colors.green.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: reminder.taken
                    ? Colors.green
                    : Colors.grey.withOpacity(0.3),
                border: Border.all(
                  color: reminder.taken ? Colors.green : Colors.grey,
                  width: 2,
                ),
              ),
              child: reminder.taken
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      decoration: reminder.taken
                          ? TextDecoration.lineThrough
                          : null,
                      color: reminder.taken
                          ? (isDark ? Colors.grey[500] : Colors.grey[400])
                          : null,
                    ),
                  ),
                  if (reminder.dose != null && reminder.dose!.isNotEmpty)
                    Text(
                      reminder.dose!,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            Text(
              reminder.time.format(context),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

