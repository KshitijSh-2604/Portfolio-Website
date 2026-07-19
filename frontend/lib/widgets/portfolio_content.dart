import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/app_provider.dart';
import '../services/api_service.dart';
import '../models/weather_model.dart';
import '../models/portfolio_model.dart';
import '../utils/auth_manager.dart';
import 'image_editor_dialog.dart';

class PortfolioContent extends StatefulWidget {
  const PortfolioContent({super.key});

  @override
  State<PortfolioContent> createState() => _PortfolioContentState();
}

class _PortfolioContentState extends State<PortfolioContent> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Animation<double>> _fadeAnims;

  final _contactNameController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactSubjectController = TextEditingController();
  final _contactMessageController = TextEditingController();
  final _contactFormKey = GlobalKey<FormState>();
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _fadeAnims = List.generate(8, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _controller,
        curve: Interval(start, (start + 0.45).clamp(0, 1), curve: Curves.easeOutExpo),
      );
    });
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _contactNameController.dispose();
    _contactEmailController.dispose();
    _contactSubjectController.dispose();
    _contactMessageController.dispose();
    super.dispose();
  }

  Future<void> _sendContactMessage() async {
    if (!_contactFormKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    try {
      await ApiService().sendContactMessage(
        name: _contactNameController.text.trim(),
        email: _contactEmailController.text.trim(),
        subject: _contactSubjectController.text.trim(),
        message: _contactMessageController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message sent successfully!')),
        );
        _contactNameController.clear();
        _contactEmailController.clear();
        _contactSubjectController.clear();
        _contactMessageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (ctx, provider, _) {
      final weather = provider.weather;
      final accent = weather.accentColor;
      final portfolio = provider.portfolio;
      final isOwner = AuthManager.isOwner;

      if (portfolio == null) {
        return Center(child: CircularProgressIndicator(color: accent));
      }

      return LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final horizontalPadding = isMobile ? 24.0 : 40.0;

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(horizontalPadding, 60, horizontalPadding, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHero(accent, provider, constraints.maxWidth, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildAbout(accent, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildExperience(accent, isMobile, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildEducation(accent, isMobile, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildSkills(accent, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildProjects(accent, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildCertifications(accent, weather, portfolio, isOwner),
              const SizedBox(height: 64),
              _buildContact(accent, constraints.maxWidth, weather),
              const SizedBox(height: 40),
            ],
          ),
        );
      });
    });
  }

  Widget _buildHero(Color accent, AppProvider provider, double maxWidth, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    final isMobile = maxWidth < 650;
    
    return FadeTransition(
      opacity: _fadeAnims[0],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero).animate(_fadeAnims[0]),
        child: isMobile 
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfilePhoto(portfolio, isOwner, accent, weather, size: 200),
                  const SizedBox(height: 32),
                  _buildHeroContent(accent, provider, portfolio, isOwner, isMobile: true, weather: weather),
                ],
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 4,
                  child: _buildHeroContent(accent, provider, portfolio, isOwner, isMobile: false, weather: weather),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 3,
                  child: Center(
                    child: _buildProfilePhoto(portfolio, isOwner, accent, weather),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildProfilePhoto(PortfolioDataModel portfolio, bool isOwner, Color accent, WeatherModel weather, {double size = 240}) {
    return Stack(
      children: [
        _AnimatedProfilePhoto(accent: accent, size: size, weather: weather, avatarUrl: portfolio.avatarUrl),
        if (isOwner)
          Positioned(
            right: 0,
            bottom: 0,
            child: _EditButton(
              onTap: () => _editAvatar(portfolio),
              icon: Icons.camera_alt_rounded,
              accent: accent,
            ),
          ),
      ],
    );
  }

  Widget _buildHeroContent(Color accent, AppProvider provider, PortfolioDataModel portfolio, bool isOwner, {required bool isMobile, required WeatherModel weather}) {
    final alignment = isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textScale = isMobile ? 0.8 : 1.0;

    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          'Hello, I\'m',
          style: TextStyle(
            color: weather.isLightBackground 
                ? const Color(0xFF1E293B) // Dark Slate
                : accent.withOpacity(0.9),
            fontSize: 16 * textScale,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isMobile ? portfolio.name : portfolio.name.replaceAll(' ', '\n'),
              textAlign: isMobile ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: weather.primaryTextColor,
                fontSize: (isMobile ? 48 : 64) * textScale,
                fontWeight: FontWeight.w800,
                height: 1.05,
                letterSpacing: -1,
              ),
            ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _EditButton(onTap: () => _editBasics(portfolio, 'name'), accent: accent),
              ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              portfolio.role,
              style: TextStyle(color: weather.secondaryTextColor, fontSize: 16 * textScale, fontWeight: FontWeight.w400),
            ),
            if (isOwner)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _EditButton(onTap: () => _editBasics(portfolio, 'role'), accent: accent, size: 24),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 16,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on_outlined, color: accent.withOpacity(0.7), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${weather.location}, India',
                  style: TextStyle(color: weather.tertiaryTextColor, fontSize: 13),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_outlined, color: accent.withOpacity(0.7), size: 14),
                const SizedBox(width: 4),
                Text(
                  '${weather.temperature.round()}°C · ${weather.description}',
                  style: TextStyle(color: weather.tertiaryTextColor, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 28),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _HeroButton(
                  icon: Icons.download_outlined,
                  label: 'Download Resume',
                  accent: accent,
                  weather: weather,
                  filled: true,
                  onTap: () => launchUrl(Uri.parse(portfolio.resumeUrl)),
                ),
                if (isOwner)
                  Positioned(
                    top: -10,
                    right: -10,
                    child: _EditButton(
                      onTap: () => _editBasics(portfolio, 'resumeUrl'),
                      accent: accent,
                      size: 24,
                    ),
                  ),
              ],
            ),
            _HeroButton(
              icon: Icons.code_rounded,
              label: 'View GitHub',
              accent: accent,
              weather: weather,
              filled: false,
              onTap: () => launchUrl(Uri.parse('https://github.com/KshitijSh-2604')),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: isMobile ? WrapAlignment.center : WrapAlignment.start,
          spacing: 12,
          runSpacing: 12,
          children: [
            _StatChip(
              icon: Icons.visibility_outlined,
              label: '${provider.totalViews} All-time Views',
              accent: accent,
              weather: weather,
            ),
            _StatChip(
              icon: Icons.people_outline_rounded,
              label: '${provider.currentViewers} Current Viewers',
              accent: accent,
              weather: weather,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAbout(Color accent, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[1],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[1]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('About', accent, weather, onAdd: isOwner ? () => _editAbout(portfolio) : null),
            const SizedBox(height: 20),
            for (final para in portfolio.about)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  para,
                  style: TextStyle(color: weather.secondaryTextColor, fontSize: 15, height: 1.75),
                ),
              ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: portfolio.socials.map((s) {
                IconData icon;
                switch (s['icon']) {
                  case 'linkedin': icon = Icons.work_rounded; break;
                  case 'email': icon = Icons.email_outlined; break;
                  case 'leetcode': icon = Icons.code_rounded; break;
                  case 'insta': icon = Icons.camera_alt_outlined; break;
                  case 'gfg': icon = Icons.school_outlined; break;
                  case 'codechef': icon = Icons.terminal_rounded; break;
                  case 'bootdev': icon = Icons.bolt_rounded; break;
                  default: icon = Icons.link_rounded;
                }
                return OutlinedButton.icon(
                  onPressed: () => launchUrl(Uri.parse(s['url']!)),
                  icon: Icon(icon, size: 14),
                  label: Text(s['label']!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: weather.secondaryTextColor,
                    side: BorderSide(color: weather.primaryTextColor.withOpacity(0.12)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExperience(Color accent, bool isMobile, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[2],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[2]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Experience', accent, weather, onAdd: isOwner ? () => _editExperience(portfolio, null) : null),
            const SizedBox(height: 20),
            for (int i = 0; i < portfolio.experience.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              Stack(
                children: [
                  _HoverCard(
                    accent: accent,
                    weather: weather,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMobile) ...[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.work_outline_rounded, color: accent, size: 22),
                            ),
                            const SizedBox(width: 16),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (isMobile) 
                                  Text(
                                    portfolio.experience[i]['period']?.toString() ?? '',
                                    style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        portfolio.experience[i]['role']?.toString() ?? '',
                                        style: TextStyle(color: weather.primaryTextColor, fontSize: 15, fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                    if (!isMobile) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: accent.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          portfolio.experience[i]['period']?.toString() ?? '',
                                          style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  portfolio.experience[i]['company']?.toString() ?? '',
                                  style: TextStyle(color: accent.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  portfolio.experience[i]['description']?.toString() ?? '',
                                  style: TextStyle(color: weather.tertiaryTextColor, fontSize: 13, height: 1.6),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isOwner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          _EditButton(onTap: () => _editExperience(portfolio, i), accent: accent, icon: Icons.edit_rounded, size: 24),
                          const SizedBox(width: 4),
                          _EditButton(onTap: () => _deletePortfolioItem(portfolio, 'experience', i), accent: accent, icon: Icons.delete_outline_rounded, size: 24),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEducation(Color accent, bool isMobile, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[3],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[3]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Education', accent, weather, onAdd: isOwner ? () => _editEducation(portfolio, null) : null),
            const SizedBox(height: 20),
            Column(
              children: [
                for (int i = 0; i < portfolio.education.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  Stack(
                    children: [
                      _HoverCard(
                        accent: accent,
                        weather: weather,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          child: Row(
                            children: [
                              if (!isMobile) ...[
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.10),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.school_outlined, color: accent, size: 20),
                                ),
                                const SizedBox(width: 16),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      portfolio.education[i]['degree']?.toString() ?? '',
                                      style: TextStyle(color: weather.primaryTextColor, fontSize: 14, fontWeight: FontWeight.w600),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      portfolio.education[i]['institute']?.toString() ?? '',
                                      style: TextStyle(color: weather.tertiaryTextColor, fontSize: 12),
                                    ),
                                    if (isMobile) ...[
                                      const SizedBox(height: 4),
                                      Text(
                                        '${portfolio.education[i]['year']!} · ${portfolio.education[i]['grade']!}',
                                        style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (!isMobile) ...[
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      portfolio.education[i]['year']?.toString() ?? '',
                                      style: TextStyle(color: accent.withOpacity(0.7), fontSize: 12, fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      portfolio.education[i]['grade']?.toString() ?? '',
                                      style: TextStyle(color: weather.secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (isOwner)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              _EditButton(onTap: () => _editEducation(portfolio, i), accent: accent, icon: Icons.edit_rounded, size: 24),
                              const SizedBox(width: 4),
                              _EditButton(onTap: () => _deletePortfolioItem(portfolio, 'education', i), accent: accent, icon: Icons.delete_outline_rounded, size: 24),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkills(Color accent, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[4],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[4]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Skills', accent, weather, onAdd: isOwner ? () => _editSkills(portfolio) : null),
            const SizedBox(height: 20),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: portfolio.skills.map((skill) => _SkillChip(label: skill as String, accent: accent, weather: weather)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjects(Color accent, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[5],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[5]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Projects', accent, weather, onAdd: isOwner ? () => _editProject(portfolio, null) : null),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 320,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.4,
              ),
              itemCount: portfolio.projects.length,
              itemBuilder: (_, i) {
                final p = portfolio.projects[i];
                return Stack(
                  children: [
                    _HoverCard(
                      accent: accent,
                      weather: weather,
                      child: InkWell(
                        onTap: (p['link'] as String?)?.isNotEmpty == true
                            ? () => launchUrl(Uri.parse(p['link'] as String))
                            : null,
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      p['title']?.toString() ?? '',
                                      style: TextStyle(color: weather.primaryTextColor, fontSize: 14, fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  if ((p['link'] as String?)?.isNotEmpty == true)
                                    Icon(Icons.open_in_new_rounded, color: accent.withOpacity(0.5), size: 14),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: Text(
                                  p['description']?.toString() ?? '',
                                  style: TextStyle(color: weather.tertiaryTextColor, fontSize: 12, height: 1.5),
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: (p['tech'] as List<dynamic>? ?? []).map((t) => Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: accent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: accent.withOpacity(0.2)),
                                  ),
                                  child: Text(t?.toString() ?? '', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
                                )).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (isOwner)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          children: [
                            _EditButton(onTap: () => _editProject(portfolio, i), accent: accent, icon: Icons.edit_rounded, size: 24),
                            const SizedBox(width: 4),
                            _EditButton(onTap: () => _deletePortfolioItem(portfolio, 'projects', i), accent: accent, icon: Icons.delete_outline_rounded, size: 24),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertifications(Color accent, WeatherModel weather, PortfolioDataModel portfolio, bool isOwner) {
    return FadeTransition(
      opacity: _fadeAnims[6],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[6]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Certifications', accent, weather, onAdd: isOwner ? () => _editCertification(portfolio, null) : null),
            const SizedBox(height: 20),
            if (portfolio.certifications.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('No certifications added yet.', style: TextStyle(color: weather.tertiaryTextColor, fontSize: 14)),
              )
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 2.2,
                ),
                itemCount: portfolio.certifications.length,
                itemBuilder: (_, i) {
                  final cert = portfolio.certifications[i];
                  final fileUrl = cert['fileUrl']?.toString() ?? '';
                  final certLink = cert['link']?.toString() ?? '';
                  final isPdf = fileUrl.toLowerCase().endsWith('.pdf');

                  return Stack(
                    children: [
                      _HoverCard(
                        accent: accent,
                        weather: weather,
                        child: InkWell(
                          onTap: fileUrl.isNotEmpty ? () => launchUrl(Uri.parse(fileUrl)) : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: weather.glassColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: fileUrl.isEmpty
                                      ? Icon(Icons.verified_user_outlined, color: accent.withOpacity(0.5), size: 32)
                                      : isPdf
                                          ? Icon(Icons.picture_as_pdf_rounded, color: Colors.red.withOpacity(0.7), size: 40)
                                          : ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Image.network(fileUrl, fit: BoxFit.cover),
                                            ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        cert['title']?.toString() ?? '',
                                        style: TextStyle(color: weather.primaryTextColor, fontSize: 15, fontWeight: FontWeight.w700),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (cert['description']?.toString().isNotEmpty == true) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          cert['description'].toString(),
                                          style: TextStyle(color: weather.tertiaryTextColor, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      if (certLink.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () => launchUrl(Uri.parse(certLink)),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.link_rounded, color: accent, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                'View Credential',
                                                style: TextStyle(color: accent, fontSize: 11, fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isOwner)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Row(
                            children: [
                              _EditButton(onTap: () => _editCertification(portfolio, i), accent: accent, icon: Icons.edit_rounded, size: 24),
                              const SizedBox(width: 4),
                              _EditButton(onTap: () => _deletePortfolioItem(portfolio, 'certifications', i), accent: accent, icon: Icons.delete_outline_rounded, size: 24),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContact(Color accent, double maxWidth, WeatherModel weather) {
    return FadeTransition(
      opacity: _fadeAnims[7],
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(_fadeAnims[7]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Contact', accent, weather),
            const SizedBox(height: 20),
            _HoverCard(
              accent: accent,
              weather: weather,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _contactFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send a Message',
                        style: TextStyle(color: weather.primaryTextColor, fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 20),
                      if (maxWidth < 450) ...[
                        _buildContactField(_contactNameController, 'Name', Icons.person_outline, accent, weather),
                        const SizedBox(height: 16),
                        _buildContactField(_contactEmailController, 'Email', Icons.email_outlined, accent, weather, isEmail: true),
                      ] else 
                        Row(
                          children: [
                            Expanded(child: _buildContactField(_contactNameController, 'Name', Icons.person_outline, accent, weather)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildContactField(_contactEmailController, 'Email', Icons.email_outlined, accent, weather, isEmail: true)),
                          ],
                        ),
                      const SizedBox(height: 16),
                      _buildContactField(_contactSubjectController, 'Subject', Icons.subject_rounded, accent, weather),
                      const SizedBox(height: 16),
                      _buildContactField(_contactMessageController, 'Message', Icons.message_outlined, accent, weather, maxLines: 5),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSending ? null : _sendContactMessage,
                          icon: _isSending 
                            ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                          label: const Text('Send Message'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accent,
                            foregroundColor: weather.onAccentColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
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
      ),
    );
  }

  Widget _buildContactField(TextEditingController ctrl, String hint, IconData icon, Color accent, WeatherModel weather, {int maxLines = 1, bool isEmail = false}) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(color: weather.primaryTextColor, fontSize: 14),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (isEmail && !v.contains('@')) return 'Invalid email';
        return null;
      },
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 18, color: weather.tertiaryTextColor),
        hintStyle: TextStyle(color: weather.tertiaryTextColor, fontSize: 14),
        filled: true,
        fillColor: weather.glassColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: weather.glassBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: weather.glassBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent.withOpacity(0.5)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _sectionHeader(String title, Color accent, WeatherModel weather, {VoidCallback? onAdd}) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 20,
          decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 12),
        Text(title, style: TextStyle(color: weather.primaryTextColor, fontSize: 22, fontWeight: FontWeight.w700)),
        if (onAdd != null)
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: _EditButton(onTap: onAdd, accent: accent, icon: Icons.add_rounded),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutExpo,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.scale(
                alignment: Alignment.centerLeft,
                scaleX: value,
                child: Container(height: 1, color: weather.primaryTextColor.withOpacity(0.06)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _editBasics(PortfolioDataModel portfolio, String field) async {
    final ctrl = TextEditingController(text: portfolio.basics[field]?.toString() ?? '');
    final result = await _showEditDialog(
      title: 'Edit ${field[0].toUpperCase()}${field.substring(1)}',
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(hintText: field),
      ),
    );
    if (result == true) {
      final updatedBasics = Map<String, dynamic>.from(portfolio.basics);
      updatedBasics[field] = ctrl.text.trim();
      await _saveSection('basics', updatedBasics);
    }
  }

  Future<void> _editAvatar(PortfolioDataModel portfolio) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();
      
      if (!mounted) return;
      final editedBytes = await showDialog<Uint8List>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => ImageEditorDialog(image: bytes, title: 'Edit Profile Photo'),
      );

      if (editedBytes != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading avatar…')));
        final url = await ApiService().uploadImage(editedBytes, 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg');
        final updatedBasics = Map<String, dynamic>.from(portfolio.basics);
        updatedBasics['avatarUrl'] = url;
        await _saveSection('basics', updatedBasics);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Avatar update failed: $e')));
      }
    }
  }

  Future<void> _editAbout(PortfolioDataModel portfolio) async {
    final ctrl = TextEditingController(text: portfolio.about.join('\n\n'));
    final result = await _showEditDialog(
      title: 'Edit About Me',
      content: TextField(
        controller: ctrl,
        maxLines: 10,
        decoration: const InputDecoration(hintText: 'Enter your bio (paragraphs separated by empty lines)'),
      ),
    );
    if (result == true) {
      final updatedBasics = Map<String, dynamic>.from(portfolio.basics);
      updatedBasics['about'] = ctrl.text.trim().split('\n\n').where((s) => s.isNotEmpty).toList();
      await _saveSection('basics', updatedBasics);
    }
  }

  Future<void> _editSkills(PortfolioDataModel portfolio) async {
    final ctrl = TextEditingController(text: portfolio.skills.join(', '));
    final result = await _showEditDialog(
      title: 'Edit Skills',
      content: TextField(
        controller: ctrl,
        decoration: const InputDecoration(hintText: 'Flutter, Dart, Python…'),
      ),
    );
    if (result == true) {
      final list = ctrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      await _saveSection('skills', list);
    }
  }

  Future<void> _editProject(PortfolioDataModel portfolio, int? index) async {
    final isNew = index == null;
    final item = !isNew ? portfolio.projects[index] : {'title': '', 'description': '', 'tech': [], 'link': ''};
    
    final titleCtrl = TextEditingController(text: item['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description']?.toString() ?? '');
    final techData = item['tech'];
    final techString = (techData is List) ? techData.join(', ') : '';
    final techCtrl = TextEditingController(text: techString);
    final linkCtrl = TextEditingController(text: item['link']?.toString() ?? '');

    final result = await _showEditDialog(
      title: isNew ? 'Add Project' : 'Edit Project',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
          TextField(controller: techCtrl, decoration: const InputDecoration(labelText: 'Technologies (comma separated)')),
          TextField(controller: linkCtrl, decoration: const InputDecoration(labelText: 'Link')),
        ],
      ),
    );

    if (result == true) {
      final newItem = {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'tech': techCtrl.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'link': linkCtrl.text.trim(),
      };
      final list = List<dynamic>.from(portfolio.projects);
      if (isNew) list.add(newItem); else list[index] = newItem;
      await _saveSection('projects', list);
    }
  }

  Future<void> _editExperience(PortfolioDataModel portfolio, int? index) async {
    final isNew = index == null;
    final item = !isNew ? portfolio.experience[index] : {'role': '', 'company': '', 'period': '', 'description': ''};
    
    final roleCtrl = TextEditingController(text: item['role']?.toString() ?? '');
    final compCtrl = TextEditingController(text: item['company']?.toString() ?? '');
    final periodCtrl = TextEditingController(text: item['period']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description']?.toString() ?? '');

    final result = await _showEditDialog(
      title: isNew ? 'Add Experience' : 'Edit Experience',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: roleCtrl, decoration: const InputDecoration(labelText: 'Role')),
          TextField(controller: compCtrl, decoration: const InputDecoration(labelText: 'Company')),
          TextField(controller: periodCtrl, decoration: const InputDecoration(labelText: 'Period')),
          TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Description')),
        ],
      ),
    );

    if (result == true) {
      final newItem = {
        'role': roleCtrl.text.trim(),
        'company': compCtrl.text.trim(),
        'period': periodCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      };
      final list = List<dynamic>.from(portfolio.experience);
      if (isNew) list.add(newItem); else list[index] = newItem;
      await _saveSection('experience', list);
    }
  }

  Future<void> _editEducation(PortfolioDataModel portfolio, int? index) async {
    final isNew = index == null;
    final item = !isNew ? portfolio.education[index] : {'degree': '', 'institute': '', 'year': '', 'grade': ''};
    
    final degCtrl = TextEditingController(text: item['degree']?.toString() ?? '');
    final instCtrl = TextEditingController(text: item['institute']?.toString() ?? '');
    final yearCtrl = TextEditingController(text: item['year']?.toString() ?? '');
    final gradeCtrl = TextEditingController(text: item['grade']?.toString() ?? '');

    final result = await _showEditDialog(
      title: isNew ? 'Add Education' : 'Edit Education',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(controller: degCtrl, decoration: const InputDecoration(labelText: 'Degree')),
          TextField(controller: instCtrl, decoration: const InputDecoration(labelText: 'Institute')),
          TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Year')),
          TextField(controller: gradeCtrl, decoration: const InputDecoration(labelText: 'Grade')),
        ],
      ),
    );

    if (result == true) {
      final newItem = {
        'degree': degCtrl.text.trim(),
        'institute': instCtrl.text.trim(),
        'year': yearCtrl.text.trim(),
        'grade': gradeCtrl.text.trim(),
      };
      final list = List<dynamic>.from(portfolio.education);
      if (isNew) list.add(newItem); else list[index] = newItem;
      await _saveSection('education', list);
    }
  }

  Future<void> _editCertification(PortfolioDataModel portfolio, int? index) async {
    final weather = context.read<AppProvider>().weather;
    final accent = weather.accentColor;
    final isNew = index == null;
    final item = !isNew ? portfolio.certifications[index] : {'title': '', 'description': '', 'fileUrl': '', 'link': ''};
    
    final titleCtrl = TextEditingController(text: item['title']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description']?.toString() ?? '');
    final linkCtrl = TextEditingController(text: item['link']?.toString() ?? '');
    String fileUrl = item['fileUrl']?.toString() ?? '';

    final result = await _showEditDialog(
      title: isNew ? 'Add Certification' : 'Edit Certification',
      content: StatefulBuilder(
        builder: (ctx, setDlg) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDialogField(titleCtrl, 'Title', Icons.title_rounded, accent),
            const SizedBox(height: 12),
            _buildDialogField(descCtrl, 'Description (Optional)', Icons.description_outlined, accent, maxLines: 3),
            const SizedBox(height: 12),
            _buildDialogField(linkCtrl, 'Credential URL (Optional)', Icons.link_rounded, accent),
            const SizedBox(height: 20),
            if (fileUrl.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    Icon(
                      fileUrl.toLowerCase().endsWith('.pdf') ? Icons.picture_as_pdf_rounded : Icons.image_rounded,
                      color: accent,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(child: Text('File attached', style: TextStyle(color: Colors.white70, fontSize: 13))),
                    IconButton(
                      onPressed: () => setDlg(() => fileUrl = ''),
                      icon: const Icon(Icons.close, size: 18, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ElevatedButton.icon(
              onPressed: () async {
                final url = await _pickFile();
                if (url != null) setDlg(() => fileUrl = url);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accent.withOpacity(0.1),
                foregroundColor: accent,
                elevation: 0,
                side: BorderSide(color: accent.withOpacity(0.3)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.upload_file_rounded, size: 18),
              label: Text(fileUrl.isEmpty ? 'Upload Image or PDF' : 'Replace File'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newItem = {
        'title': titleCtrl.text.trim(),
        'description': descCtrl.text.trim(),
        'link': linkCtrl.text.trim(),
        'fileUrl': fileUrl,
      };
      final list = List<dynamic>.from(portfolio.certifications);
      if (isNew) list.add(newItem); else list[index] = newItem;
      await _saveSection('certifications', list);
    }
  }

  Widget _buildDialogField(TextEditingController ctrl, String label, IconData icon, Color accent, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: Colors.white38),
        labelStyle: const TextStyle(color: Colors.white38, fontSize: 14),
        filled: true,
        fillColor: Colors.white.withOpacity(0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: accent.withOpacity(0.5)),
        ),
      ),
    );
  }

  Future<String?> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
        withData: true,
      );
      if (result != null && result.files.single.bytes != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading file…')));
        return await ApiService().uploadImage(result.files.single.bytes!, result.files.single.name);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
    return null;
  }

  Future<void> _deletePortfolioItem(PortfolioDataModel portfolio, String section, int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to remove this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      final List<dynamic> list;
      if (section == 'projects') list = List<dynamic>.from(portfolio.projects);
      else if (section == 'experience') list = List<dynamic>.from(portfolio.experience);
      else if (section == 'education') list = List<dynamic>.from(portfolio.education);
      else if (section == 'certifications') list = List<dynamic>.from(portfolio.certifications);
      else return;

      list.removeAt(index);
      await _saveSection(section, list);
    }
  }

  Future<void> _saveSection(String section, dynamic content) async {
    try {
      await context.read<AppProvider>().updatePortfolioSection(section, content);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$section updated successfully!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update $section: $e')));
    }
  }

  Future<bool?> _showEditDialog({required String title, required Widget content}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(child: Theme(data: ThemeData.dark(), child: content)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final VoidCallback onTap;
  final Color accent;
  final IconData icon;
  final double size;
  const _EditButton({required this.onTap, required this.accent, this.icon = Icons.edit_rounded, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: accent.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: accent.withOpacity(0.3))),
        child: Icon(icon, color: accent, size: size * 0.6),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final WeatherModel weather;
  const _StatChip({required this.icon, required this.label, required this.accent, required this.weather});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: weather.glassColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: weather.glassBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent.withOpacity(0.7)),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(color: weather.primaryTextColor.withOpacity(0.8), fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final WeatherModel weather;
  final bool filled;
  final VoidCallback onTap;

  const _HeroButton({required this.icon, required this.label, required this.accent, required this.weather, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: filled ? accent : weather.glassColor,
        foregroundColor: filled ? weather.onAccentColor : weather.primaryTextColor,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: filled ? BorderSide.none : BorderSide(color: weather.glassBorderColor),
        ),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SkillChip extends StatefulWidget {
  final String label;
  final Color accent;
  final WeatherModel weather;
  const _SkillChip({required this.label, required this.accent, required this.weather});

  @override
  State<_SkillChip> createState() => _SkillChipState();
}

class _SkillChipState extends State<_SkillChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: _hovered ? widget.accent.withOpacity(0.2) : widget.weather.glassColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: _hovered ? widget.accent.withOpacity(0.5) : widget.weather.glassBorderColor,
          ),
          boxShadow: _hovered ? [BoxShadow(color: widget.accent.withOpacity(0.1), blurRadius: 10)] : [],
        ),
        child: Text(
          widget.label,
          style: TextStyle(
            color: _hovered 
              ? (widget.weather.isLightBackground ? widget.accent : Colors.white)
              : widget.weather.secondaryTextColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HoverCard extends StatefulWidget {
  final Widget child;
  final Color accent;
  final WeatherModel weather;
  const _HoverCard({required this.child, required this.accent, required this.weather});

  @override
  State<_HoverCard> createState() => _HoverCardState();
}

class _HoverCardState extends State<_HoverCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _scale;
  late Animation<double> _shadow;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scale = Tween<double>(begin: 1.0, end: 1.02).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    _shadow = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _c.forward(),
      onExit: (_) => _c.reverse(),
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => Transform.scale(
          scale: _scale.value,
          child: Container(
            decoration: BoxDecoration(
              color: Color.lerp(widget.weather.glassColor, widget.weather.primaryTextColor.withOpacity(0.08), _c.value),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color.lerp(widget.weather.glassBorderColor, widget.accent.withOpacity(0.4), _c.value)!,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.accent.withOpacity(0.12 * _shadow.value),
                  blurRadius: 20 * _shadow.value,
                  offset: Offset(0, 10 * _shadow.value),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: child,
            ),
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

class _AnimatedProfilePhoto extends StatefulWidget {
  final Color accent;
  final double size;
  final WeatherModel weather;
  final String avatarUrl;

  const _AnimatedProfilePhoto({
    super.key,
    required this.accent,
    this.size = 240,
    required this.weather,
    required this.avatarUrl,
  });

  @override
  State<_AnimatedProfilePhoto> createState() => _AnimatedProfilePhotoState();
}

class _AnimatedProfilePhotoState extends State<_AnimatedProfilePhoto> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final weather = widget.weather;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ProfileWeatherPainter(
            accent: widget.accent,
            condition: weather.condition,
            progress: _controller.value,
          ),
          child: Container(
            width: widget.size,
            height: widget.size,
            padding: const EdgeInsets.all(6),
            child: ClipOval(
              child: Image.network(
                widget.avatarUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white.withOpacity(0.05),
                  child: Icon(
                    Icons.person,
                    color: weather.tertiaryTextColor,
                    size: widget.size * 0.33,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileWeatherPainter extends CustomPainter {
  final Color accent;
  final WeatherCondition condition;
  final double progress;

  _ProfileWeatherPainter({required this.accent, required this.condition, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    switch (condition) {
      case WeatherCondition.sunny:
      case WeatherCondition.sunnyClouds:
        _drawSunnyEffect(canvas, center, radius);
        break;
      case WeatherCondition.rain:
      case WeatherCondition.heavyRain:
      case WeatherCondition.rainThunder:
        _drawRainEffect(canvas, center, radius);
        break;
      case WeatherCondition.drizzle:
        _drawDrizzleEffect(canvas, center, radius);
        break;
      case WeatherCondition.thunderstorm:
        _drawThunderEffect(canvas, center, radius);
        break;
      case WeatherCondition.snow:
        _drawSnowEffect(canvas, center, radius);
        break;
      case WeatherCondition.mist:
        _drawMistEffect(canvas, center, radius);
        break;
      case WeatherCondition.haze:
        _drawHazeEffect(canvas, center, radius);
        break;
      case WeatherCondition.fog:
        _drawFogEffect(canvas, center, radius);
        break;
      case WeatherCondition.clear:
        _drawClearEffect(canvas, center, radius);
        break;
      default:
        _drawDefaultEffect(canvas, center, radius);
    }
  }

  void _drawSunnyEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [accent.withOpacity(0), accent, accent.withOpacity(0)],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius + 10));
    
    canvas.drawCircle(center, radius + 4, paint..style = PaintingStyle.stroke..strokeWidth = 3);
    
    // Sun rays
    final rayPaint = Paint()..color = accent.withOpacity(0.3)..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2 + (progress * pi);
      final start = Offset(center.dx + cos(angle) * (radius + 6), center.dy + sin(angle) * (radius + 6));
      final end = Offset(center.dx + cos(angle) * (radius + 14), center.dy + sin(angle) * (radius + 14));
      canvas.drawLine(start, end, rayPaint);
    }
  }

  void _drawRainEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    
    // Fast, more opaque ripples for heavy rain
    for (int i = 0; i < 4; i++) {
      final p = (progress * 1.5 + (i / 4)) % 1.0;
      final r = radius + (p * 20);
      canvas.drawCircle(center, r, paint..color = accent.withOpacity(0.6 * (1 - p)));
    }
  }

  void _drawDrizzleEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // Slow, soft breathing ripples for drizzle
    for (int i = 0; i < 2; i++) {
      final p = (progress * 0.5 + (i / 2)) % 1.0;
      final r = radius + (p * 10);
      canvas.drawCircle(center, r, paint..color = accent.withOpacity(0.3 * (1 - p)));
    }
  }

  void _drawThunderEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    
    if (Random().nextDouble() > 0.8) {
      final boltPaint = Paint()..color = Colors.white..strokeWidth = 2;
      final angle = Random().nextDouble() * pi * 2;
      final start = Offset(center.dx + cos(angle) * radius, center.dy + sin(angle) * radius);
      final end = Offset(center.dx + cos(angle) * (radius + 20), center.dy + sin(angle) * (radius + 20));
      canvas.drawLine(start, end, boltPaint);
    }
    
    canvas.drawCircle(center, radius + 4, paint..color = accent.withOpacity(0.3 + 0.7 * sin(progress * pi * 10).abs()));
  }

  void _drawSnowEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()..color = Colors.white.withOpacity(0.5)..style = PaintingStyle.stroke..strokeWidth = 2;
    canvas.drawCircle(center, radius + 4, paint);
    
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * pi * 2 + (progress * 0.5);
      final offset = Offset(center.dx + cos(angle) * (radius + 8), center.dy + sin(angle) * (radius + 8));
      canvas.drawCircle(offset, 2, paint..style = PaintingStyle.fill);
    }
  }

  void _drawMistEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFFB0BEC5).withOpacity(0.4 + 0.2 * sin(progress * pi * 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius + 4, paint);
  }

  void _drawHazeEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [const Color(0xFFDECBA4).withOpacity(0), const Color(0xFFDECBA4), const Color(0xFFDECBA4).withOpacity(0)],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius + 10));
    canvas.drawCircle(center, radius + 4, paint..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawFogEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = const Color(0xFF606C88).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    
    final p = (sin(progress * pi * 2).abs());
    canvas.drawCircle(center, radius + 4 + (p * 4), paint..color = const Color(0xFF606C88).withOpacity(0.3 * p));
    canvas.drawCircle(center, radius + 4, paint..color = const Color(0xFF606C88).withOpacity(0.6));
  }

  void _drawClearEffect(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..shader = SweepGradient(
        colors: [accent.withOpacity(0), accent, accent.withOpacity(0)],
        transform: GradientRotation(progress * pi * 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius + 10));
    
    canvas.drawCircle(center, radius + 4, paint..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawDefaultEffect(Canvas canvas, Offset center, double radius) {
    canvas.drawCircle(center, radius + 4, Paint()..color = accent.withOpacity(0.2)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
