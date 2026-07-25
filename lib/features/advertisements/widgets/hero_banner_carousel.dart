import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/advertisement_model.dart';
import '../viewmodels/advertisement_viewmodel.dart';
import 'package:kisan_dost/features/mandi/ui/mandi_screen.dart';
import '../../marketplace/ui/marketplace_screen.dart';
import '../../business/ui/business_page_screen.dart';

class HeroBannerCarousel extends StatefulWidget {
  const HeroBannerCarousel({super.key});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _controller = PageController();
  int _current = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdvertisementViewModel>().loadAds();
    });
    _startAutoSlide();
  }

  void _startAutoSlide() {
    Future.delayed(const Duration(seconds: 5), () {
      if (!mounted) return;
      final ads = context.read<AdvertisementViewModel>().ads;
      if (ads.isEmpty) {
        _startAutoSlide();
        return;
      }
      final next = (_current + 1) % ads.length;
      if (_controller.hasClients) {
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      }
      _startAutoSlide();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdvertisementViewModel>();

    if (vm.isLoading) {
      return _shimmer();
    }

    if (!vm.hasAds) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _current = i),
            itemCount: vm.ads.length,
            itemBuilder: (context, index) {
              return _AdCard(
                ad: vm.ads[index],
                onTap: () => _onTap(vm, vm.ads[index]),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _Indicators(
          count: vm.ads.length,
          current: _current,
        ),
      ],
    );
  }

  // NOTE: made async so we can await canLaunchUrl / launchUrl for the
  // 'external' redirect type.
  Future<void> _onTap(AdvertisementViewModel vm, AdvertisementModel ad) async {
    vm.onAdClicked(ad);
    switch (ad.redirectType) {
      case 'products':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
        );
        break;

      case 'dealer':
        if (ad.redirectId.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BusinessPageScreen(
                userId: ad.redirectId,
              ),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
          );
        }
        break;

      case 'external':
        if (ad.redirectUrl.isEmpty) break;
        final url = Uri.tryParse(ad.redirectUrl);
        if (url == null) break;
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication,
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link open nahi ho saka')),
          );
        }
        break;

      case 'mandi':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const MandiScreen()),
        );
        break;
    }
  }

  Widget _shimmer() {
    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(22),
      ),
    );
  }
}

class _AdCard extends StatelessWidget {
  final AdvertisementModel ad;
  final VoidCallback onTap;

  const _AdCard({required this.ad, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Banner Image
              ad.bannerImage.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: ad.bannerImage,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: const Color(0xFF1A6B3A).withValues(alpha: 0.2),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: const Color(0xFF1A6B3A),
                        child: const Icon(Icons.image_not_supported,
                            color: Colors.white54, size: 40),
                      ),
                    )
                  : Container(color: const Color(0xFF1A6B3A)),

              // Dark Gradient Overlay
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),

              // Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Company name
                    Text(
                      ad.companyName,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.8),
                        letterSpacing: 0.5,
                        height: 1.4,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),

                    // Headline
                    Text(
                      ad.headline,
                      style: const TextStyle(
                        fontFamily: 'Nastaleeq',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.8,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6B3A),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF1A6B3A)
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.arrow_back_ios,
                              color: Colors.white,
                              size: 12,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              ad.buttonText,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                height: 1.4,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  final int count;
  final int current;

  const _Indicators({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: current == i ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                current == i ? const Color(0xFF1A6B3A) : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}
