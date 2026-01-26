import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/app_bar_with_actions.dart';

class ExercisePlan {
  ExercisePlan({
    required this.title,
    required this.focus,
    required this.durationMinutes,
    required this.level,
    required this.description,
    required this.steps,
    required this.equipment,
    this.isCompleted = false,
  });

  final String title;
  final String focus;
  final int durationMinutes;
  final String level;
  final String description;
  final List<String> steps;
  final String equipment;
  bool isCompleted;
}

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final List<ExercisePlan> _plans = [
    ExercisePlan(
      title: 'Peregangan Leher',
      focus: 'Fleksibilitas',
      durationMinutes: 5,
      level: 'Ringan',
      description:
          'Gerakan perlahan untuk meredakan tegang otot leher dan bahu setelah duduk lama.',
      equipment: 'Kursi stabil',
      steps: [
        'Duduk tegak, tarik napas dalam.',
        'Miringkan kepala ke kanan selama 10 detik lalu ke kiri.',
        'Tundukkan dagu ke dada, tahan 10 detik.',
        'Putar bahu ke depan dan ke belakang 10 kali.',
      ],
    ),
    ExercisePlan(
      title: 'Latihan Genggaman',
      focus: 'Kekuatan',
      durationMinutes: 7,
      level: 'Ringan',
      description:
          'Melatih genggaman tangan untuk membantu aktivitas harian seperti memegang gelas.',
      equipment: 'Bola karet / hand gripper',
      steps: [
        'Pegang bola karet di telapak tangan.',
        'Remas selama 3 detik lalu lepaskan perlahan.',
        'Ulangi 12 kali untuk setiap tangan.',
        'Lakukan 2 set dengan jeda 1 menit.',
      ],
    ),
    ExercisePlan(
      title: 'Latihan Duduk-Berdiri',
      focus: 'Keseimbangan',
      durationMinutes: 8,
      level: 'Sedang',
      description:
          'Meningkatkan kekuatan paha dan koordinasi tubuh bagian bawah.',
      equipment: 'Kursi tanpa roda',
      steps: [
        'Duduk tegak dengan kaki menapak lantai.',
        'Silangkan tangan di dada atau pegang kursi bila perlu.',
        'Berdiri perlahan sambil menghembuskan napas.',
        'Duduk kembali sambil menahan gerakan, ulangi 10 kali.',
      ],
    ),
    ExercisePlan(
      title: 'Weight Shift',
      focus: 'Koordinasi',
      durationMinutes: 6,
      level: 'Sedang',
      description:
          'Melatih perpindahan berat badan untuk mempersiapkan berjalan mandiri.',
      equipment: 'Meja tinggi / sandaran',
      steps: [
        'Berdiri di belakang kursi dan pegang sandaran.',
        'Pindahkan berat badan ke kaki kanan selama 5 detik.',
        'Kembali ke tengah lalu pindahkan ke kaki kiri.',
        'Tambahkan ayunan tangan kecil bila stabil.',
      ],
    ),
    ExercisePlan(
      title: 'Latihan Jalan di Tempat',
      focus: 'Kardio Ringan',
      durationMinutes: 10,
      level: 'Intens',
      description:
          'Meningkatkan stamina jantung dengan gerakan aman di dalam ruangan.',
      equipment: 'Sepatu nyaman',
      steps: [
        'Berdiri tegak, tarik napas dalam.',
        'Angkat lutut kanan setinggi pinggul, lalu turunkan.',
        'Lakukan bergantian kiri dan kanan selama 2 menit.',
        'Istirahat 30 detik, ulangi 3 kali.',
      ],
    ),
    ExercisePlan(
      title: 'Latihan Lengan Duduk',
      focus: 'Mobilitas',
      durationMinutes: 6,
      level: 'Ringan',
      description:
          'Mengaktifkan otot bahu dan punggung atas untuk membantu aktivitas merapikan diri.',
      equipment: 'Band elastis / handuk panjang',
      steps: [
        'Pegang band dengan kedua tangan sejajar bahu.',
        'Tarik band ke luar sambil menahan bahu tetap rileks.',
        'Tahan 3 detik lalu kembali ke posisi awal.',
        'Ulangi 12 kali, istirahat, lalu ulangi 2 set.',
      ],
    ),
  ];

  final List<String> _levels = const ['Semua', 'Ringan', 'Sedang', 'Intens'];
  String _selectedLevel = 'Semua';

  List<ExercisePlan> get _visiblePlans {
    if (_selectedLevel == 'Semua') return _plans;
    return _plans.where((plan) => plan.level == _selectedLevel).toList();
  }

  int get _completedMinutes => _plans
      .where((plan) => plan.isCompleted)
      .fold(0, (total, plan) => total + plan.durationMinutes);

  void _toggleCompletion(ExercisePlan plan) {
    setState(() => plan.isCompleted = !plan.isCompleted);
  }

  void _showSteps(ExercisePlan plan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return FractionallySizedBox(
          heightFactor: 0.85,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Langkah ${plan.title}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Durasi ±${plan.durationMinutes} menit • ${plan.level}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.separated(
                      itemCount: plan.steps.length,
                      separatorBuilder: (_, __) => const Divider(height: 20),
                      itemBuilder: (_, index) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          foregroundColor: Colors.blue.shade700,
                          child: Text('${index + 1}'),
                        ),
                        title: Text(plan.steps[index]),
                      ),
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                        ),
                        child: const Text('Mengerti, siap latihan'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      'Awali latihan dengan peregangan 2 menit untuk memanaskan otot.',
      'Berhenti sejenak jika terasa pusing atau nyeri tajam.',
      'Catat latihan yang selesai agar tenaga medis dapat memantau progres.',
    ];

    return Card(
      margin: const EdgeInsets.only(top: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Tips Fisioterapis',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontSize: 16)),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes = _plans.fold<int>(
      0,
      (total, plan) => total + plan.durationMinutes,
    );
    final completedCount = _plans.where((plan) => plan.isCompleted).length;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBarWithActions(
        title: 'Latihan Pemulihan',
        showThemeToggle: true,
        showLanguageToggle: true,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 100),
        children: [
          _ExerciseSummaryCard(
            completed: completedCount,
            total: _plans.length,
            totalMinutes: totalMinutes,
            completedMinutes: _completedMinutes,
          ),
          const SizedBox(height: 16),
          const Text(
            'Pilih Tingkat Latihan',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _levels
                .map(
                  (level) => ChoiceChip(
                    label: Text(level),
                    selected: _selectedLevel == level,
                    onSelected: (_) => setState(() => _selectedLevel = level),
                    selectedColor: Colors.blue.shade100,
                    labelStyle: TextStyle(
                      color: _selectedLevel == level
                          ? Colors.blue.shade900
                          : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
                .toList(),
          ),
          _buildTipsCard(),
          const SizedBox(height: 24),
          const Text(
            'Rencana Latihan Hari Ini',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_visiblePlans.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
              ),
              child: Column(
                children: const [
                  Icon(Icons.inbox_outlined, size: 36, color: Colors.grey),
                  SizedBox(height: 12),
                  Text(
                    'Belum ada latihan untuk filter ini.',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Coba pilih tingkat latihan lain atau konsultasikan dengan fisioterapis Anda.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            )
          else
            ..._visiblePlans.map(
              (plan) => _ExerciseCard(
                plan: plan,
                onToggle: () => _toggleCompletion(plan),
                onShowSteps: () => _showSteps(plan),
              ),
            ),
        ],
      ),
    );
  }
}

class _ExerciseSummaryCard extends StatelessWidget {
  const _ExerciseSummaryCard({
    required this.completed,
    required this.total,
    required this.totalMinutes,
    required this.completedMinutes,
  });

  final int completed;
  final int total;
  final int totalMinutes;
  final int completedMinutes;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade300],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200.withOpacity(0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Mingguan',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$completed dari $total latihan',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryItem(
                  label: 'Target Waktu',
                  value: '$totalMinutes menit',
                ),
              ),
              Container(
                width: 1,
                height: 36,
                color: Colors.white.withOpacity(0.4),
              ),
              Expanded(
                child: _SummaryItem(
                  label: 'Sudah Dikerjakan',
                  value: '$completedMinutes menit',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.plan,
    required this.onToggle,
    required this.onShowSteps,
  });

  final ExercisePlan plan;
  final VoidCallback onToggle;
  final VoidCallback onShowSteps;

  @override
  Widget build(BuildContext context) {
    final accentColor = plan.isCompleted
        ? Colors.green.shade600
        : Colors.blue.shade600;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: accentColor.withOpacity(0.12),
                  child: Icon(
                    plan.isCompleted
                        ? Icons.check_circle
                        : Icons.self_improvement_outlined,
                    color: accentColor,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        plan.focus,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    plan.level,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.description,
              style: const TextStyle(color: Colors.black87, height: 1.3),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  icon: Icons.timer,
                  label: '${plan.durationMinutes} mnt',
                ),
                _InfoChip(
                  icon: Icons.chair_alt_outlined,
                  label: plan.equipment,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Langkah Latihan'),
                    onPressed: onShowSteps,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: Icon(
                      plan.isCompleted
                          ? Icons.refresh_rounded
                          : Icons.check_circle_rounded,
                    ),
                    label: Text(plan.isCompleted ? 'Ulangi' : 'Tandai Selesai'),
                    onPressed: onToggle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade800),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
