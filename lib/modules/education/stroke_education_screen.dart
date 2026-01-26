import 'package:flutter/material.dart';
import '../../widgets/app_bar_with_actions.dart';

class StrokeEducationScreen extends StatelessWidget {
  const StrokeEducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBarWithActions(
        title: 'Edukasi Stroke',
        showThemeToggle: true,
        showLanguageToggle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Apa itu Stroke?',
            icon: Icons.health_and_safety_rounded,
            color: Colors.red,
            isDark: isDark,
            children: [
              _InfoText(
                'Stroke adalah kondisi medis serius yang terjadi ketika aliran darah ke otak terganggu atau terputus. Hal ini dapat menyebabkan kerusakan sel-sel otak dan berpotensi mengakibatkan kecacatan permanen atau bahkan kematian.',
              ),
              const SizedBox(height: 12),
              _Subtitle('Jenis-jenis Stroke:'),
              const SizedBox(height: 8),
              _BulletPoint('Stroke Iskemik: Terjadi ketika pembuluh darah tersumbat (80% kasus)'),
              _BulletPoint('Stroke Hemoragik: Terjadi ketika pembuluh darah pecah (20% kasus)'),
              _BulletPoint('TIA (Transient Ischemic Attack): Stroke ringan yang sembuh dalam 24 jam'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Tanda dan Gejala (FAST)',
            icon: Icons.warning_rounded,
            color: Colors.orange,
            isDark: isDark,
            children: [
              _InfoText(
                'Kenali tanda-tanda stroke dengan metode FAST untuk penanganan cepat:',
              ),
              const SizedBox(height: 16),
              _FastItem('F', 'Face (Wajah)', 'Wajah mencong atau tidak simetris, salah satu sisi wajah terlihat turun'),
              _FastItem('A', 'Arm (Lengan)', 'Lengan melemah atau mati rasa, sulit mengangkat kedua lengan'),
              _FastItem('S', 'Speech (Bicara)', 'Bicara pelo, tidak jelas, atau sulit memahami pembicaraan'),
              _FastItem('T', 'Time (Waktu)', 'Segera hubungi ambulans 119 atau bawa ke rumah sakit terdekat'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Faktor Risiko',
            icon: Icons.medical_services_rounded,
            color: Colors.purple,
            isDark: isDark,
            children: [
              _Subtitle('Faktor yang Dapat Dikontrol:'),
              const SizedBox(height: 8),
              _BulletPoint('Tekanan darah tinggi (hipertensi)'),
              _BulletPoint('Diabetes melitus'),
              _BulletPoint('Kolesterol tinggi'),
              _BulletPoint('Merokok'),
              _BulletPoint('Obesitas'),
              _BulletPoint('Kurang aktivitas fisik'),
              _BulletPoint('Konsumsi alkohol berlebihan'),
              const SizedBox(height: 16),
              _Subtitle('Faktor yang Tidak Dapat Dikontrol:'),
              const SizedBox(height: 8),
              _BulletPoint('Usia (risiko meningkat setelah 55 tahun)'),
              _BulletPoint('Jenis kelamin (pria lebih berisiko)'),
              _BulletPoint('Riwayat keluarga stroke'),
              _BulletPoint('Riwayat stroke sebelumnya'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Pencegahan',
            icon: Icons.shield_rounded,
            color: Colors.green,
            isDark: isDark,
            children: [
              _Subtitle('1. Kontrol Tekanan Darah'),
              _InfoText('Jaga tekanan darah di bawah 120/80 mmHg dengan diet sehat dan olahraga teratur.'),
              const SizedBox(height: 12),
              _Subtitle('2. Kelola Diabetes'),
              _InfoText('Kontrol gula darah dengan diet, olahraga, dan obat sesuai anjuran dokter.'),
              const SizedBox(height: 12),
              _Subtitle('3. Pola Makan Sehat'),
              _InfoText('Kurangi garam, lemak jenuh, dan gula. Perbanyak sayur, buah, dan biji-bijian.'),
              const SizedBox(height: 12),
              _Subtitle('4. Olahraga Teratur'),
              _InfoText('Lakukan aktivitas fisik minimal 30 menit, 5 kali seminggu.'),
              const SizedBox(height: 12),
              _Subtitle('5. Berhenti Merokok'),
              _InfoText('Merokok meningkatkan risiko stroke 2-4 kali lipat.'),
              const SizedBox(height: 12),
              _Subtitle('6. Batasi Alkohol'),
              _InfoText('Konsumsi alkohol maksimal 1-2 gelas per hari untuk pria, 1 gelas untuk wanita.'),
              const SizedBox(height: 12),
              _Subtitle('7. Kelola Stres'),
              _InfoText('Stres kronis dapat meningkatkan tekanan darah. Lakukan relaksasi dan meditasi.'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Penanganan',
            icon: Icons.local_hospital_rounded,
            color: Colors.blue,
            isDark: isDark,
            children: [
              _Subtitle('Golden Period (3-4.5 Jam)'),
              _InfoText(
                'Penanganan dalam 3-4.5 jam pertama sangat krusial. Semakin cepat ditangani, semakin besar peluang pemulihan.',
              ),
              const SizedBox(height: 16),
              _Subtitle('Langkah Penanganan:'),
              const SizedBox(height: 8),
              _NumberedPoint('1', 'Segera hubungi ambulans 119 atau bawa ke rumah sakit terdekat'),
              _NumberedPoint('2', 'Jangan berikan makanan atau minuman (risiko tersedak)'),
              _NumberedPoint('3', 'Jangan berikan obat tanpa resep dokter'),
              _NumberedPoint('4', 'Catat waktu munculnya gejala pertama'),
              _NumberedPoint('5', 'Bawa catatan medis dan daftar obat yang dikonsumsi'),
              const SizedBox(height: 16),
              _Subtitle('Perawatan di Rumah Sakit:'),
              const SizedBox(height: 8),
              _BulletPoint('Terapi trombolitik (untuk stroke iskemik)'),
              _BulletPoint('Operasi (untuk stroke hemoragik)'),
              _BulletPoint('Rehabilitasi: fisioterapi, terapi wicara, terapi okupasi'),
              _BulletPoint('Obat-obatan: antikoagulan, antiplatelet, statin'),
            ],
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Rehabilitasi Pasca Stroke',
            icon: Icons.fitness_center_rounded,
            color: Colors.teal,
            isDark: isDark,
            children: [
              _InfoText(
                'Rehabilitasi penting untuk memulihkan fungsi tubuh dan meningkatkan kualitas hidup.',
              ),
              const SizedBox(height: 12),
              _Subtitle('Jenis Rehabilitasi:'),
              const SizedBox(height: 8),
              _BulletPoint('Fisioterapi: Memulihkan gerakan dan keseimbangan'),
              _BulletPoint('Terapi Wicara: Memulihkan kemampuan berbicara dan menelan'),
              _BulletPoint('Terapi Okupasi: Memulihkan kemampuan aktivitas sehari-hari'),
              _BulletPoint('Terapi Psikologis: Mengatasi depresi dan kecemasan'),
            ],
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 100), // Space for navbar
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _InfoText extends StatelessWidget {
  final String text;

  const _InfoText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: isDark ? Colors.grey[300] : Colors.grey[700],
      ),
    );
  }
}

class _Subtitle extends StatelessWidget {
  final String text;

  const _Subtitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  final String text;

  const _BulletPoint(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedPoint extends StatelessWidget {
  final String number;
  final String text;

  const _NumberedPoint(this.number, this.text);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastItem extends StatelessWidget {
  final String letter;
  final String title;
  final String description;

  const _FastItem(this.letter, this.title, this.description);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.orange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                letter,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

