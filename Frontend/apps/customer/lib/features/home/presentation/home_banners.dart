import 'package:flutter/material.dart' hide Banner;
import 'package:go_router/go_router.dart';
import 'package:pao_api/pao_api.dart';
import 'package:pao_customer/app/routes.dart';
import 'package:pao_customer/shared/formats.dart';
import 'package:pao_customer/shared/l10n.dart';
import 'package:pao_ui/pao_ui.dart';

/// The greeting over the address: the customer's first name when known.
class HomeGreeting extends StatelessWidget {
  /// Creates the greeting for [name].
  const HomeGreeting({required this.name, super.key});

  /// The customer's name, if set.
  final String? name;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final first = name?.trim().split(RegExp(r'\s+')).first ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first.isEmpty
              ? context.t.homeGreetingNoName
              : context.t.homeGreeting(first),
          style: text.headlineSmall,
        ),
        const SizedBox(height: PaoSpace.xs),
        Text(context.t.homeGreetingAsk, style: text.bodyMedium),
      ],
    );
  }
}

/// The admin-managed banners (C07), swiped sideways with page dots.
class HomeBanners extends StatefulWidget {
  /// Creates the carousel for [banners].
  const HomeBanners({required this.banners, super.key});

  /// Published banners in display order.
  final List<Banner> banners;

  @override
  State<HomeBanners> createState() => _HomeBannersState();
}

class _HomeBannersState extends State<HomeBanners> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    return Column(
      children: [
        SizedBox(
          // Fits two Bangla lines of title and subtitle at the larger scale.
          height: 168,
          child: PageView(
            onPageChanged: (i) => setState(() => _page = i),
            children: [for (final b in banners) BannerCard(banner: b)],
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: PaoSpace.sm),
          _Dots(count: banners.length, current: _page),
        ],
      ],
    );
  }
}

/// One banner: the image when it loads, otherwise the accent's deep colour.
class BannerCard extends StatelessWidget {
  /// Creates the card for [banner].
  const BannerCard({required this.banner, super.key});

  /// The banner.
  final Banner banner;

  @override
  Widget build(BuildContext context) {
    final accent = context.pao.accent;
    final text = Theme.of(context).textTheme;
    final service = banner.serviceId;
    final subtitle = banner.subtitle;
    final image = banner.imageUrl;
    return Material(
      color: accent.deep,
      shape: const RoundedRectangleBorder(borderRadius: PaoShape.leaf),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: service == null
            ? null
            : () => context.push(Routes.serviceOf(service)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (image != null)
              Image.network(
                image,
                fit: BoxFit.cover,
                color: accent.deep.withValues(alpha: 0.45),
                colorBlendMode: BlendMode.darken,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(PaoSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    context.local(banner.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleLarge!.copyWith(color: Colors.white),
                  ),
                  if (subtitle != null)
                    Text(
                      context.local(subtitle),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodyMedium!.copyWith(color: accent.tint),
                    ),
                  if (service != null) ...[
                    const SizedBox(height: PaoSpace.sm),
                    Text(
                      '${context.t.homeBannerOpen} →',
                      style: text.labelLarge!.copyWith(color: accent.soft),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (var i = 0; i < count; i++)
        AnimatedContainer(
          duration: PaoMotion.fast,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: i == current ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: i == current ? context.pao.action : context.pao.hairline,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
    ],
  );
}
