import 'dart:math' as math;
import 'dart:ui';

import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_home_screen_controller.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_brand.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/controllers/landlord_landing_instance.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_brand_image.dart';
import 'package:belluga_now/presentation/landlord_area/home/screens/landlord_home_screen/widgets/landlord_phone_mockup.dart';
import 'package:flutter/material.dart';

const _phoneHomeScreenshot = 'assets/images/landlord_landing_home.png';
const _phoneMapScreenshot = 'assets/images/landlord_landing_map.png';
const _phoneDiscoveryScreenshot =
    'assets/images/landlord_landing_discovery.png';

class LandlordLandingContent extends StatelessWidget {
  const LandlordLandingContent({
    super.key,
    required this.state,
    required this.controller,
  });

  final LandlordHomeUiState state;
  final LandlordHomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: state.brand.background,
      child: SingleChildScrollView(
        controller: controller.scrollController,
        child: Column(
          children: [
            _HeroSection(
              state: state,
              onInstancesPressed: controller.scrollToInstances,
              onContactPressed: controller.scrollToFooter,
            ),
            KeyedSubtree(
              key: controller.problemSectionKey,
              child: _ProblemSection(brand: state.brand),
            ),
            KeyedSubtree(
              key: controller.solutionSectionKey,
              child: _SolutionSection(brand: state.brand),
            ),
            KeyedSubtree(
              key: controller.ecosystemSectionKey,
              child: _EcosystemSection(brand: state.brand),
            ),
            KeyedSubtree(
              key: controller.instancesSectionKey,
              child: _InstancesSection(
                brand: state.brand,
                instances: state.instances,
                onInstancePressed: controller.openInstance,
              ),
            ),
            KeyedSubtree(
              key: controller.footerSectionKey,
              child: _FooterSection(
                brand: state.brand,
                onContactPressed: controller.openWhatsAppContact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.state,
    required this.onInstancesPressed,
    required this.onContactPressed,
  });

  final LandlordHomeUiState state;
  final VoidCallback onInstancesPressed;
  final VoidCallback onContactPressed;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        return Stack(
          children: [
            Positioned.fill(
              child: _HeroBackdrop(brand: state.brand),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                isDesktop ? 40 : 20,
                isDesktop ? 132 : 112,
                isDesktop ? 40 : 20,
                isDesktop ? 112 : 64,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: isDesktop
                      ? Row(
                          children: [
                            Expanded(
                              child: _HeroCopy(
                                brand: state.brand,
                                onInstancesPressed: onInstancesPressed,
                                onContactPressed: onContactPressed,
                              ),
                            ),
                            const SizedBox(width: 54),
                            LandlordPhoneMockup(
                              brand: state.brand,
                              rotated: true,
                              screenshotAssetPath: _phoneHomeScreenshot,
                            ),
                          ],
                        )
                      : _HeroCopy(
                          brand: state.brand,
                          onInstancesPressed: onInstancesPressed,
                          onContactPressed: onContactPressed,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _HeroBackdrop extends StatelessWidget {
  const _HeroBackdrop({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    final heroImageUrl = brand.heroImageUrl?.trim();
    return Stack(
      fit: StackFit.expand,
      children: [
        if (heroImageUrl != null && heroImageUrl.isNotEmpty)
          Image.network(
            heroImageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                brand.slate,
                brand.slate.withValues(alpha: 0.92),
                brand.primary.withValues(alpha: 0.58),
              ],
              stops: const [0, 0.58, 1],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        Positioned(
          top: -120,
          right: -80,
          child: _BlurCircle(color: brand.rose, size: 320),
        ),
        Positioned(
          bottom: -140,
          left: 280,
          child: _BlurCircle(color: brand.primary, size: 280),
        ),
      ],
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({
    required this.brand,
    required this.onInstancesPressed,
    required this.onContactPressed,
  });

  final LandlordLandingBrand brand;
  final VoidCallback onInstancesPressed;
  final VoidCallback onContactPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: const Text(
            'Turismo 4.0 para cidades vivas',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'O que tem para fazer hoje?',
          style: textTheme.displayMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                height: 0.95,
                letterSpacing: -1.8,
              ) ??
              const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 54,
              ),
        ),
        const SizedBox(height: 20),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Text(
            'Bóora! conecta moradores, turistas, negócios locais e gestão pública em uma experiência única de descoberta hiperlocal.',
            style: textTheme.titleLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 30),
        Wrap(
          spacing: 14,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: onInstancesPressed,
              icon: const Icon(Icons.travel_explore),
              label: const Text('Instâncias Ativas'),
              style: FilledButton.styleFrom(
                backgroundColor: brand.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onContactPressed,
              icon: const Icon(Icons.location_city),
              label: const Text('Bóora! na Sua Cidade'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProblemSection extends StatelessWidget {
  const _ProblemSection({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return _SectionShell(
      child: Column(
        children: [
          Transform.rotate(
            angle: -0.1,
            child: Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: brand.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: brand.accent,
                size: 40,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'A cidade acontece, mas a experiência se perde.',
            textAlign: TextAlign.center,
            style: textTheme.headlineMedium?.copyWith(
              color: brand.slate,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 14),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Text(
              'Eventos, artistas, praias, rotas e negócios vivem espalhados em canais desconectados. O resultado é FOMO para o visitante e baixa previsibilidade para quem move a economia local.',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium?.copyWith(
                color: brand.slate.withValues(alpha: 0.68),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolutionSection extends StatelessWidget {
  const _SolutionSection({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final phones = [
          _ShowcasePhone(
            brand: brand,
            title: 'Agenda viva',
            icon: Icons.event_available,
            glowColor: Colors.blue,
            screenshotAssetPath: _phoneHomeScreenshot,
          ),
          _ShowcasePhone(
            brand: brand,
            title: 'Mapa inteligente',
            icon: Icons.map_outlined,
            glowColor: brand.accent,
            lift: isDesktop,
            screenshotAssetPath: _phoneMapScreenshot,
          ),
          _ShowcasePhone(
            brand: brand,
            title: 'Rede local',
            icon: Icons.groups_2_outlined,
            glowColor: brand.primary,
            screenshotAssetPath: _phoneDiscoveryScreenshot,
          ),
        ];
        return _SectionShell(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              _SectionHeader(
                brand: brand,
                eyebrow: 'A solução',
                title: 'Uma camada digital para viver a cidade em tempo real.',
                subtitle:
                    'A mesma base entrega descoberta pública, presença, mapas e inteligência local para operação urbana e comercial.',
              ),
              const SizedBox(height: 46),
              isDesktop
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: phones
                          .map(
                            (phone) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: phone,
                            ),
                          )
                          .toList(growable: false),
                    )
                  : Column(
                      children: phones
                          .map(
                            (phone) => Padding(
                              padding: const EdgeInsets.only(bottom: 28),
                              child: phone,
                            ),
                          )
                          .toList(growable: false),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _ShowcasePhone extends StatelessWidget {
  const _ShowcasePhone({
    required this.brand,
    required this.title,
    required this.icon,
    required this.glowColor,
    this.lift = false,
    required this.screenshotAssetPath,
  });

  final LandlordLandingBrand brand;
  final String title;
  final IconData icon;
  final Color glowColor;
  final bool lift;
  final String screenshotAssetPath;

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 270,
          height: 270,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withValues(alpha: 0.34),
                glowColor.withValues(alpha: 0),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: 0.28),
                blurRadius: 48,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 0.72,
          child: LandlordPhoneMockup(
            brand: brand,
            title: title,
            accentIcon: icon,
            screenshotAssetPath: screenshotAssetPath,
          ),
        ),
      ],
    );

    if (!lift) {
      return child;
    }
    return Transform.translate(offset: const Offset(0, -48), child: child);
  }
}

class _EcosystemSection extends StatelessWidget {
  const _EcosystemSection({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 900;
        final copy = _EcosystemCopy(brand: brand);
        final map = _AbstractMapCard(brand: brand);
        return _SectionShell(
          child: isDesktop
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: copy),
                    const SizedBox(width: 56),
                    Expanded(child: map),
                  ],
                )
              : Column(
                  children: [
                    copy,
                    const SizedBox(height: 36),
                    map,
                  ],
                ),
        );
      },
    );
  }
}

class _EcosystemCopy extends StatelessWidget {
  const _EcosystemCopy({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          brand: brand,
          eyebrow: 'Ecossistema',
          title: 'Turismo 4.0 & Smart Cities',
          subtitle:
              'Quatro lados da cidade conectados por uma experiência simples para quem usa e estratégica para quem opera.',
          centered: false,
        ),
        const SizedBox(height: 32),
        _EcosystemItem(
          brand: brand,
          icon: Icons.home_rounded,
          title: 'Morador',
          text:
              'Descobre o que acontece ao seu redor e usufrui da cultura da própria cidade, gerando sentimento de pertencimento.',
          color: brand.primary,
        ),
        _EcosystemItem(
          brand: brand,
          icon: Icons.camera_alt_rounded,
          title: 'Turista',
          text:
              'Encontra experiências reais, validadas e curadas por moradores.',
          color: brand.accent,
        ),
        _EcosystemItem(
          brand: brand,
          icon: Icons.storefront_rounded,
          title: 'Trade',
          text:
              'Acesso direto aos clientes e fãs que os seguem, com dados analíticos avançados através do FRM (Fanbase Relationship Manager).',
          color: brand.rose,
        ),
        _EcosystemItem(
          brand: brand,
          icon: Icons.analytics_rounded,
          title: 'Gestão',
          text:
              'Integração a Mapas Culturais e Turísticos melhorando, em tempo real, os dados relevantes para a tomada de decisões.',
          color: Colors.blue,
        ),
      ],
    );
  }
}

class _EcosystemItem extends StatelessWidget {
  const _EcosystemItem({
    required this.brand,
    required this.icon,
    required this.title,
    required this.text,
    required this.color,
  });

  final LandlordLandingBrand brand;
  final IconData icon;
  final String title;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    color: brand.slate,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: textTheme.bodyLarge?.copyWith(
                    color: brand.slate.withValues(alpha: 0.64),
                    height: 1.38,
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

class _AbstractMapCard extends StatelessWidget {
  const _AbstractMapCard({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: -50,
          right: -50,
          child: _BlurCircle(color: brand.primary, size: 160),
        ),
        Positioned(
          bottom: -60,
          left: -50,
          child: _BlurCircle(color: brand.rose, size: 180),
        ),
        Container(
          height: 420,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: brand.slate.withValues(alpha: 0.14),
                blurRadius: 38,
                offset: const Offset(0, 24),
              ),
            ],
          ),
          padding: const EdgeInsets.all(28),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: CustomPaint(
              painter: _AbstractMapPainter(brand: brand),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ],
    );
  }
}

class _InstancesSection extends StatelessWidget {
  const _InstancesSection({
    required this.brand,
    required this.instances,
    required this.onInstancePressed,
  });

  final LandlordLandingBrand brand;
  final List<LandlordLandingInstance> instances;
  final ValueChanged<LandlordLandingInstance> onInstancePressed;

  @override
  Widget build(BuildContext context) {
    final futureInstances = const [
      'Alfredo Chaves',
      'Anchieta',
      'Grande Vitória',
    ];
    return _SectionShell(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _SectionHeader(
            brand: brand,
            eyebrow: 'Rede Bóora!',
            title: 'Instâncias conectadas por uma plataforma única.',
            subtitle:
                'Cada cidade opera com identidade própria, mantendo a mesma base tecnológica e governança de experiência.',
          ),
          const SizedBox(height: 34),
          if (instances.isEmpty)
            _EmptyInstanceCard(brand: brand)
          else
            Wrap(
              spacing: 22,
              runSpacing: 22,
              alignment: WrapAlignment.center,
              children: instances
                  .map(
                    (instance) => _ActiveInstanceCard(
                      instance: instance,
                      onPressed: () => onInstancePressed(instance),
                    ),
                  )
                  .toList(growable: false),
            ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 18,
            runSpacing: 18,
            alignment: WrapAlignment.center,
            children: futureInstances
                .map((name) => _FutureInstanceCard(name: name))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _ActiveInstanceCard extends StatelessWidget {
  const _ActiveInstanceCard({
    required this.instance,
    required this.onPressed,
  });

  final LandlordLandingInstance instance;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            instance.primaryColor,
            instance.primaryColor.withValues(alpha: 0.72),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: instance.primaryColor.withValues(alpha: 0.32),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              LandlordBrandImage(
                url: instance.logoUrl,
                fallbackLabel: instance.name.isEmpty
                    ? 'B'
                    : instance.name.substring(0, 1).toUpperCase(),
                width: 64,
                height: 64,
                foregroundColor: instance.primaryColor,
                backgroundColor: Colors.white,
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Ativa',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            instance.name,
            style: textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            instance.domain,
            style: textTheme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: const Text('Conhecer instância'),
          ),
        ],
      ),
    );
  }
}

class _EmptyInstanceCard extends StatelessWidget {
  const _EmptyInstanceCard({required this.brand});

  final LandlordLandingBrand brand;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: brand.background,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: brand.slate.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Icon(Icons.public, color: brand.primary, size: 34),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Nenhuma instância pública foi retornada pelo environment configurado.',
              style: textTheme.titleMedium?.copyWith(
                color: brand.slate,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FutureInstanceCard extends StatelessWidget {
  const _FutureInstanceCard({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Opacity(
      opacity: 0.7,
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.add_location_alt_outlined, color: Colors.black54),
            const SizedBox(height: 18),
            Text(
              name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: null,
              child: const Text('Em breve'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FooterSection extends StatelessWidget {
  const _FooterSection({
    required this.brand,
    required this.onContactPressed,
  });

  final LandlordLandingBrand brand;
  final Future<void> Function() onContactPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: brand.slate,
        border: Border(top: BorderSide(color: brand.secondary, width: 4)),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -160,
            left: -120,
            child: _BlurCircle(color: brand.primary, size: 360),
          ),
          Positioned(
            bottom: -180,
            right: -100,
            child: _BlurCircle(color: brand.secondary, size: 380),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 96, 24, 76),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: Column(
                  children: [
                    Text(
                      'Leve o Bóora! para a sua cidade.',
                      textAlign: TextAlign.center,
                      style: textTheme.displaySmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Converse com a equipe para desenhar uma instância com identidade local, dados dinâmicos e operação conectada ao ecossistema Belluga.',
                      textAlign: TextAlign.center,
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 30),
                    FilledButton.icon(
                      onPressed: () {
                        onContactPressed();
                      },
                      icon: const Icon(Icons.mark_email_unread_outlined),
                      label: const Text('Fale com a Equipe'),
                      style: FilledButton.styleFrom(
                        backgroundColor: brand.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 18,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.child,
    this.backgroundColor,
  });

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 92),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1180),
          child: child,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.brand,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.centered = true,
  });

  final LandlordLandingBrand brand;
  final String eyebrow;
  final String title;
  final String subtitle;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final alignment =
        centered ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = centered ? TextAlign.center : TextAlign.left;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          eyebrow.toUpperCase(),
          textAlign: textAlign,
          style: textTheme.labelLarge?.copyWith(
            color: brand.primary,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Text(
            title,
            textAlign: textAlign,
            style: textTheme.headlineMedium?.copyWith(
              color: brand.slate,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.04,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Text(
            subtitle,
            textAlign: textAlign,
            style: textTheme.titleMedium?.copyWith(
              color: brand.slate.withValues(alpha: 0.66),
              height: 1.45,
            ),
          ),
        ),
      ],
    );
  }
}

class _BlurCircle extends StatelessWidget {
  const _BlurCircle({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.26),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _AbstractMapPainter extends CustomPainter {
  const _AbstractMapPainter({required this.brand});

  final LandlordLandingBrand brand;

  @override
  void paint(Canvas canvas, Size size) {
    final background = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Offset.zero & size, background);

    final gridPaint = Paint()
      ..color = brand.slate.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (var x = 28.0; x < size.width; x += 58) {
      _drawDashedLine(
        canvas,
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    for (var y = 28.0; y < size.height; y += 58) {
      _drawDashedLine(
        canvas,
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }

    final nodes = [
      Offset(size.width * 0.24, size.height * 0.32),
      Offset(size.width * 0.62, size.height * 0.24),
      Offset(size.width * 0.74, size.height * 0.62),
      Offset(size.width * 0.38, size.height * 0.72),
    ];

    final linkPaint = Paint()
      ..color = brand.primary.withValues(alpha: 0.38)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < nodes.length; i++) {
      final next = nodes[(i + 1) % nodes.length];
      _drawDashedLine(canvas, nodes[i], next, linkPaint, dashWidth: 12);
    }

    for (var i = 0; i < nodes.length; i++) {
      final color =
          [brand.primary, brand.accent, brand.rose, brand.secondary][i % 4];
      final outerPaint = Paint()..color = color.withValues(alpha: 0.18);
      final innerPaint = Paint()..color = color;
      canvas.drawCircle(nodes[i], 28, outerPaint);
      canvas.drawCircle(nodes[i], 10, innerPaint);
    }
  }

  void _drawDashedLine(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint paint, {
    double dashWidth = 8,
    double dashGap = 8,
  }) {
    final delta = end - start;
    final distance = delta.distance;
    if (distance == 0) {
      return;
    }
    final direction = delta / distance;
    var current = 0.0;
    while (current < distance) {
      final next = math.min(current + dashWidth, distance);
      canvas.drawLine(
        start + direction * current,
        start + direction * next,
        paint,
      );
      current = next + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant _AbstractMapPainter oldDelegate) {
    return oldDelegate.brand != brand;
  }
}
