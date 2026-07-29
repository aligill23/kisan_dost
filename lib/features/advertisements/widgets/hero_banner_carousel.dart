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
    try {
      // Video pehle download/cache karo, phir local file se play karo
      final file =
          await DefaultCacheManager().getSingleFile(widget.ad.videoUrl);

      _videoCtrl = VideoPlayerController.file(file);
      await _videoCtrl!.initialize();
      _videoCtrl!.setLooping(true);
      _videoCtrl!.setVolume(0);
      _videoCtrl!.play();
      if (mounted) setState(() => _videoReady = true);
    } catch (e) {
      debugPrint('Video load error: $e');
    }
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
              // ── Media — Image or Video ─────────
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
                    color: const Color(0xFF1A6B3A).withValues(alpha: 0.2),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: const Color(0xFF1A6B3A),
                  ),
                )
              else
                Container(color: const Color(0xFF1A6B3A)),

              // ── Video badge ───────────────────
              if (widget.ad.mediaType == 'video')
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_filled,
                          color: Colors.white,
                          size: 14,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'VIDEO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // ── Content ───────────────────────
              // ── Content ───────────────────────
              // ── Content ───────────────────────
              Positioned(
                bottom: 14,
                left: 14,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Company name - apna alag box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.ad.companyName,
                        style: TextStyle(
                          fontFamily:
                              'Roboto', // ya 'Poppins', ya jo bhi English font pubspec mein add ho
                          fontSize: 5,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Headline - apna alag box
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.ad.headline,
                        style: const TextStyle(
                          fontFamily: 'Nastaleeq',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.6,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Button - already alag hai
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A6B3A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.ad.buttonText,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            height: 1.4,
                          ),
                          textDirection: TextDirection.rtl,
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
