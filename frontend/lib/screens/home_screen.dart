import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../widgets/weather_overlay.dart';
import '../widgets/post_feed.dart';
import '../widgets/portfolio_content.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Offset _mousePos = Offset.zero;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final gradients = provider.weather.backgroundGradient;

      return Scaffold(
        backgroundColor: Colors.transparent,
        body: MouseRegion(
          onHover: (event) => setState(() => _mousePos = event.localPosition),
          child: AnimatedContainer(
            duration: const Duration(seconds: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradients,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                // Weather particle overlay
                Positioned.fill(
                  child: IgnorePointer(
                    child: WeatherOverlay(
                      condition: provider.weather.condition,
                      mousePosition: _mousePos,
                    ),
                  ),
                ),
                // Main layout
                Positioned.fill(
                  child: LayoutBuilder(builder: (_, constraints) {
                    final isMobile = constraints.maxWidth < 900;
                    if (isMobile) return _buildMobileLayout(context, provider);
                    return _buildDesktopLayout(context, constraints.maxWidth);
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildDesktopLayout(BuildContext context, double width) {
    return Row(
      children: [
        Expanded(
          flex: 65,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.white.withOpacity(0.05))),
            ),
            child: const PortfolioContent(),
          ),
        ),
        SizedBox(
          width: (width * 0.35).clamp(300, 420),
          child: const PostFeed(),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, AppProvider provider) {
    final weather = provider.weather;
    return DefaultTabController(
      length: 2,
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: TabBarView(
              children: [
                const PortfolioContent(),
                const PostFeed(),
              ],
            ),
          ),
          // Floating Glass TabBar at the bottom for better reachability/impact
          Positioned(
            left: 20,
            right: 20,
            bottom: 20 + MediaQuery.of(context).padding.bottom,
            child: Container(
              height: 64,
              decoration: BoxDecoration(
                color: weather.glassColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: weather.glassBorderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: TabBar(
                  tabs: const [
                    Tab(icon: Icon(Icons.person_outline_rounded, size: 20), text: 'Me'),
                    Tab(icon: Icon(Icons.auto_awesome_mosaic_rounded, size: 20), text: 'Snapshots'),
                  ],
                  labelColor: weather.primaryTextColor,
                  unselectedLabelColor: weather.tertiaryTextColor,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: weather.accentColor.withOpacity(0.15),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, letterSpacing: 0.5),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
