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
      child: Column(
        children: [
          ClipRRect(
            child: Container(
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8),
              decoration: BoxDecoration(
                color: weather.isLightBackground ? Colors.black.withOpacity(0.05) : Colors.black.withOpacity(0.2),
                border: Border(bottom: BorderSide(color: weather.primaryTextColor.withOpacity(0.06))),
              ),
              child: TabBar(
                tabs: const [
                  Tab(text: 'Portfolio'),
                  Tab(text: 'Life Snapshots'),
                ],
                labelColor: weather.primaryTextColor,
                unselectedLabelColor: weather.tertiaryTextColor,
                indicatorColor: weather.accentColor,
                dividerColor: Colors.transparent,
                labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
          ),
          const Expanded(
            child: TabBarView(
              children: [PortfolioContent(), PostFeed()],
            ),
          ),
        ],
      ),
    );
  }
}
