import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart'; // ADD THIS
import '../models/advertisement_model.dart';
import '../viewmodels/advertisement_viewmodel.dart';
import 'package:kisan_dost/features/mandi/ui/mandi_screen.dart';
import '../../marketplace/ui/marketplace_screen.dart';
import '../../business/ui/business_page_screen.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
        AspectRatio(
          aspectRatio: 16 / 9,
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

// hero_banner_carousel.dart mein
// _AdCard replace karo:

class _AdCard extends StatefulWidget {
  final AdvertisementModel ad;
  final VoidCallback onTap;

  const _AdCard({required this.ad, required this.onTap});

  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  @override
  void initState() {
    super.initState();
    if (widget.ad.mediaType == 'video' && widget.ad.videoUrl.isNotEmpty) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    _videoCtrl = VideoPlayerController.networkUrl(
      Uri.parse(widget.ad.videoUrl),
    );
    await _videoCtrl!.initialize();
    _videoCtrl!.setLooping(true);
    _videoCtrl!.setVolume(0);
    _videoCtrl!.play();
    if (mounted) setState(() => _videoReady = true);
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Media ─────────────────────────
              if (widget.ad.mediaType == 'video' &&
                  _videoReady &&
                  _videoCtrl != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _videoCtrl!.value.size.width,
                    height: _videoCtrl!.value.size.height,
                    child: VideoPlayer(_videoCtrl!),
                  ),
                )
              else if (widget.ad.bannerImage.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: widget.ad.bannerImage,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: Colors.grey.shade200,
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1A6B3A),
                  ),
                )
              else
                Container(color: const Color(0xFF1A6B3A)),

              // ── Light overlay top ──────────────
              // Sirf top pe — Sponsored badge ke liye
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── Light overlay bottom ───────────
              // Sirf bottom pe — CTA button ke liye
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // ── TOP — Sponsored badge only ─────
              Positioned(
                top: 10,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 0.5,
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium,
                        color: Colors.white,
                        size: 11,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Sponsored',
                        style: TextStyle(
                          // ✅ Default Flutter font
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── BOTTOM — CTA only ──────────────
              Positioned(
                bottom: 12,
                left: 14,
                right: 14,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ✅ CTA Button — right
                    GestureDetector(
                      onTap: widget.onTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.ad.buttonText,
                              style: const TextStyle(
                                // ✅ Default Flutter font
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A6B3A),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF1A6B3A),
                              size: 14,
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
