import 'package:flutter/material.dart';

/// ==========================================================
/// Design tokens & komponen bersama untuk fitur Rekap Kelas.
/// Dipisah ke sini supaya warna & style konsisten antara
/// halaman list dan detail, dan gampang di-maintain di satu
/// tempat kalau ada perubahan tema.
/// ==========================================================

class KelasPalette {
  KelasPalette._();

  // Warna utama — biru solid, bukan gradient pastel.
  static const Color primary = Color(0xFF1B56D6);
  static const Color primaryDeep = Color(0xFF0F3D91);

  // Teks & background netral.
  static const Color ink = Color(0xFF16233B);
  static const Color slate = Color(0xFF5C6B85);
  static const Color slateMuted = Color(0xFF95A2B8);
  static const Color surface = Color(0xFFF2F5FA);
  static const Color border = Color(0xFFE3E8F2);

  // Status.
  static const Color positive = Color(0xFF14805C);
  static const Color positiveBg = Color(0xFFDCF3E9);
  static const Color negative = Color(0xFFD34848);
  static const Color negativeBg = Color(0xFFFBE4E4);

  /// Palet biru-teal-indigo yang senada, dipakai untuk badge
  /// jurusan supaya tiap jurusan punya identitas warna yang
  /// konsisten tanpa keluar dari keluarga warna biru.
  static const List<Color> jurusanPalette = [
    Color(0xFF1B56D6),
    Color(0xFF0E7C86),
    Color(0xFF3949AB),
    Color(0xFF1976A6),
    Color(0xFF2F5F98),
    Color(0xFF5C6BC0),
  ];

  /// Hash sederhana & deterministik: jurusan yang sama akan
  /// selalu dapat warna yang sama di seluruh aplikasi.
  static Color jurusanColor(String seed) {
    if (seed.trim().isEmpty) return primary;
    final hash = seed.codeUnits.fold<int>(0, (acc, c) => acc + c);
    return jurusanPalette[hash % jurusanPalette.length];
  }
}

/// Ambil inisial (maks 2 huruf) dari nama, dipakai untuk avatar.
String initialsFrom(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

/// Grid tipis ala kertas blueprint, dipakai sebagai tekstur
/// halus di atas header biru solid — bukan dekorasi acak,
/// tapi motif "cetak biru" yang relevan sama tema teknis/data.
class BlueprintGridPainter extends CustomPainter {
  final Color lineColor;
  final double gap;

  const BlueprintGridPainter({this.lineColor = Colors.white, this.gap = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant BlueprintGridPainter oldDelegate) => false;
}

/// Badge kode kelas — kotak rounded berwarna sesuai jurusan,
/// isinya tingkat kelas (mis. "XI") dalam monospace, dipakai
/// konsisten di kartu list & header detail.
class ClassCodeBadge extends StatelessWidget {
  final String grade;
  final String major;
  final double size;

  const ClassCodeBadge({
    super.key,
    required this.grade,
    required this.major,
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    final color = KelasPalette.jurusanColor(major);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        grade,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
          fontSize: size * 0.3,
          color: Colors.white,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

/// Pill statistik translucent, dipakai di atas header biru.
class RecapStatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const RecapStatPill({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pill filter tap-able (jurusan, status, dll), dipakai di
/// kedua halaman untuk menjaga interaksi filter tetap konsisten.
class RecapFilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const RecapFilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? KelasPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? KelasPalette.primary : KelasPalette.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : KelasPalette.slate,
          ),
        ),
      ),
    );
  }
}

/// Search field bergaya seragam untuk list kelas & list siswa.
class RecapSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;

  const RecapSearchField({
    super.key,
    required this.controller,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 13.5, color: KelasPalette.ink),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          color: KelasPalette.slateMuted,
          fontSize: 13,
        ),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: KelasPalette.slate,
          size: 20,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KelasPalette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KelasPalette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: KelasPalette.primary, width: 1.4),
        ),
      ),
    );
  }
}

/// Kotak shimmer sederhana tanpa dependency tambahan, dipakai
/// untuk skeleton loading yang terasa lebih hidup dibanding
/// spinner polos.
class ShimmerBox extends StatefulWidget {
  final double height;
  final double width;
  final BorderRadius borderRadius;

  const ShimmerBox({
    super.key,
    required this.height,
    this.width = double.infinity,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
  });

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              colors: const [
                Color(0xFFE7ECF4),
                Color(0xFFF6F8FC),
                Color(0xFFE7ECF4),
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1 + 2 * t, 0),
              end: Alignment(1 + 2 * t, 0),
            ).createShader(rect);
          },
          child: Container(
            height: widget.height,
            width: widget.width,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: widget.borderRadius,
            ),
          ),
        );
      },
    );
  }
}

/// Wrapper animasi fade + slide-up bertahap untuk item list,
/// bikin daftar terasa dinamis pas pertama kali muncul tanpa
/// mengganggu saat scroll biasa.
class StaggeredFadeIn extends StatefulWidget {
  final int index;
  final Widget child;

  const StaggeredFadeIn({super.key, required this.index, required this.child});

  @override
  State<StaggeredFadeIn> createState() => _StaggeredFadeInState();
}

class _StaggeredFadeInState extends State<StaggeredFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    final delay = Duration(milliseconds: 40 * widget.index.clamp(0, 8));
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// State kosong yang seragam — ikon lingkaran + judul + saran
/// tindakan, dipakai untuk "belum ada data" maupun "hasil filter
/// kosong".
class RecapEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const RecapEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: KelasPalette.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: KelasPalette.primary, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: KelasPalette.ink,
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KelasPalette.slateMuted,
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// State error seragam dengan tombol coba lagi.
class RecapErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const RecapErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: KelasPalette.negativeBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: KelasPalette.negative,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: KelasPalette.slate,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: OutlinedButton.styleFrom(
                foregroundColor: KelasPalette.primary,
                side: const BorderSide(color: KelasPalette.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
