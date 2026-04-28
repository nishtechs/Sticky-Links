import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_container.dart';
import '../widgets/dynamic_background.dart';
import '../constants.dart';

class WhatsNewPage extends StatelessWidget {
  const WhatsNewPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      body: DynamicBackground(
        isEnabled: true, // Always show during onboarding for 'WOW' factor
        seedColor: settings.themeColor,
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 40,
                  ),
                  child: GlassContainer(
                    isEnabled: true,
                    borderRadius: 32,
                    opacity: 0.1,
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header
                          Hero(
                            tag: 'app_logo',
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              size: 80,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "What's New in Sticky Links v${AppConstants.appVersion}",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "The ultimate cross-platform bookmarking tool just got better.",
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.outline,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 40),

                          // Feature List
                          AnimationLimiter(
                            child: ListView(
                              shrinkWrap: true,
                              children: AnimationConfiguration.toStaggeredList(
                                duration: const Duration(milliseconds: 500),
                                childAnimationBuilder: (widget) =>
                                    SlideAnimation(
                                      verticalOffset: 30.0,
                                      child: FadeInAnimation(child: widget),
                                    ),
                                children: [
                                  _buildFeatureItem(
                                    context,
                                    Icons.category_rounded,
                                    'Category Filter Fix',
                                    'Fixed a critical bug where clicking "All" category would freeze the app. Category switching is now instant and reliable.',
                                    colorScheme.primary,
                                  ),
                                  _buildFeatureItem(
                                    context,
                                    Icons.info_outline_rounded,
                                    'Smarter Empty States',
                                    'When a category has no links, you now see a clear message like "No links in Design" instead of a confusing blank screen.',
                                    colorScheme.secondary,
                                  ),
                                  _buildFeatureItem(
                                    context,
                                    Icons.tune_rounded,
                                    'Consistent Category Selection',
                                    'The "All" category now stays highlighted correctly on startup and after switching between categories.',
                                    colorScheme.tertiary,
                                  ),
                                  _buildFeatureItem(
                                    context,
                                    Icons.build_circle_rounded,
                                    'Under-The-Hood Polish',
                                    'Internal state management improvements for smoother filtering, sorting, and navigation.',
                                    colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 48),

                          // Action
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: FilledButton(
                              onPressed: () {
                                settings.markWhatsNewSeen();
                                Navigator.of(context).pop();
                              },
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                "Let's Get Started",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
    Color iconColor,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.outline,
                    height: 1.4,
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
