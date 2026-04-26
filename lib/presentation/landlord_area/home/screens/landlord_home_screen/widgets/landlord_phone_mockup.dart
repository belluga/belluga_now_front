import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_brand.dart';
import 'package:flutter/material.dart';

class LandlordPhoneMockup extends StatelessWidget {
  const LandlordPhoneMockup({
    super.key,
    required this.brand,
    this.rotated = false,
    this.title = 'Hoje na cidade',
    this.accentIcon = Icons.explore_outlined,
    this.screenshotAssetPath,
    this.screenContent,
  });

  final LandlordLandingBrand brand;
  final bool rotated;
  final String title;
  final IconData accentIcon;
  final String? screenshotAssetPath;
  final Widget? screenContent;

  @override
  Widget build(BuildContext context) {
    final phone = Container(
      width: 284,
      height: 560,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(48),
        border: Border.all(width: 4, color: Colors.black),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(38),
                child: _PhoneScreen(
                  brand: brand,
                  title: title,
                  accentIcon: accentIcon,
                  screenshotAssetPath: screenshotAssetPath,
                  screenContent: screenContent,
                ),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 84,
                height: 24,
                decoration: const BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (!rotated) {
      return phone;
    }

    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(0.08)
        ..rotateY(-0.26),
      child: phone,
    );
  }
}

class _PhoneScreen extends StatelessWidget {
  const _PhoneScreen({
    required this.brand,
    required this.title,
    required this.accentIcon,
    this.screenshotAssetPath,
    this.screenContent,
  });

  final LandlordLandingBrand brand;
  final String title;
  final IconData accentIcon;
  final String? screenshotAssetPath;
  final Widget? screenContent;

  @override
  Widget build(BuildContext context) {
    final screenContent = this.screenContent;
    if (screenContent != null) {
      return screenContent;
    }

    final screenshotAssetPath = this.screenshotAssetPath;
    if (screenshotAssetPath != null) {
      return Image.asset(
        screenshotAssetPath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
      );
    }

    return Container(
      color: const Color(0xFF111827),
      padding: const EdgeInsets.fromLTRB(18, 48, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: brand.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(accentIcon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _SearchBar(brand: brand),
          const SizedBox(height: 18),
          _ChipRow(brand: brand),
          const SizedBox(height: 18),
          Expanded(
            child: ListView(
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _PhoneCard(
                  brand: brand,
                  icon: Icons.music_note,
                  title: 'Show ao vivo',
                  subtitle: 'Hoje • 19:30',
                ),
                _PhoneCard(
                  brand: brand,
                  icon: Icons.restaurant,
                  title: 'Rota gastronômica',
                  subtitle: '12 lugares próximos',
                ),
                _PhoneCard(
                  brand: brand,
                  icon: Icons.beach_access,
                  title: 'Pôr do sol',
                  subtitle: 'Experiência recomendada',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.search, color: brand.secondary, size: 20),
          const SizedBox(width: 10),
          Text(
            'O que tem para fazer?',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          ),
        ],
      ),
    );
  }
}

class _ChipRow extends StatelessWidget {
  const _ChipRow({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _PhoneChip(label: 'Agora', color: brand.secondary),
        _PhoneChip(label: 'Mapa', color: brand.primary),
        _PhoneChip(label: 'Agenda', color: brand.rose),
      ],
    );
  }
}

class _PhoneChip extends StatelessWidget {
  const _PhoneChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({
    required this.brand,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final LandlordLandingBrand brand;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: brand.primary.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: brand.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.66),
                    fontWeight: FontWeight.w600,
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
