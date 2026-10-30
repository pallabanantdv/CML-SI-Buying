import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../config/constants/app_constants.dart';
import '../../../config/routes/route_names.dart';
import '../../../config/theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _animationDuration = Duration(milliseconds: 2200);
  static const _displayPause = Duration(milliseconds: 650);
  static const _brandWords = ['CAML', 'SI', 'Buying'];

  late final AnimationController _controller;
  late final List<Animation<double>> _wordReveals;
  late final Animation<double> _brandLabelReveal;
  late final Animation<double> _accentReveal;
  late AuthViewModel _auth;
  bool _started = false;
  bool _animationComplete = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _wordReveals = [
      for (var index = 0; index < _brandWords.length; index++)
        CurvedAnimation(
          parent: _controller,
          curve: Interval(
            index * 0.13,
            0.56 + index * 0.13,
            curve: Curves.easeOutCubic,
          ),
        ),
    ];
    _brandLabelReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.48, curve: Curves.easeOutCubic),
    );
    _accentReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 0.88, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _auth = context.read<AuthViewModel>();
    if (!AppConstants.bypassLoginForModulePreview && !_auth.initialized) {
      _auth.addListener(_onAuthChanged);
    }
    unawaited(_playSplash(MediaQuery.of(context).disableAnimations));
  }

  Future<void> _playSplash(bool reduceMotion) async {
    if (reduceMotion) {
      _controller.value = 1;
    } else {
      await _controller.forward();
      await Future<void>.delayed(_displayPause);
    }
    if (!mounted) return;
    _animationComplete = true;
    _navigateWhenReady();
  }

  void _onAuthChanged() {
    if (_animationComplete) _navigateWhenReady();
  }

  void _navigateWhenReady() {
    if (!mounted || !_animationComplete || _hasNavigated) return;
    if (!AppConstants.bypassLoginForModulePreview && !_auth.initialized) {
      return;
    }

    _hasNavigated = true;
    _auth.removeListener(_onAuthChanged);
    final destination =
        AppConstants.bypassLoginForModulePreview || _auth.isAuthenticated
        ? RouteNames.dashboard
        : RouteNames.login;
    context.goNamed(destination);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _brandLabelReveal,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.16),
                          end: Offset.zero,
                        ).animate(_brandLabelReveal),
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: AppSpacing.small,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            Text(
                              'PROCUREMENT WORKSPACE',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontSize: constraints.maxWidth < 300 ? 10 : 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    Semantics(
                      label: 'CAML SI Buying',
                      child: ExcludeSemantics(
                        child: Wrap(
                          alignment: WrapAlignment.center,
                          spacing: AppSpacing.small,
                          runSpacing: AppSpacing.xSmall,
                          children: [
                            for (
                              var index = 0;
                              index < _brandWords.length;
                              index++
                            )
                              _buildAnimatedWord(
                                index,
                                theme,
                                constraints.maxWidth,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    AnimatedBuilder(
                      animation: _accentReveal,
                      builder: (context, child) => Opacity(
                        opacity: _accentReveal.value,
                        child: SizedBox(
                          width: 68 * _accentReveal.value,
                          height: 2,
                          child: child,
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(1),
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
    );
  }

  Widget _buildAnimatedWord(int index, ThemeData theme, double availableWidth) {
    final reveal = _wordReveals[index];
    final style = theme.textTheme.headlineMedium?.copyWith(
      color: index == 1
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurface,
      fontSize: availableWidth < 300 ? 22 : 27,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.35,
    );

    return FadeTransition(
      opacity: reveal,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.22),
          end: Offset.zero,
        ).animate(reveal),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(reveal),
          child: Text(_brandWords[index], style: style),
        ),
      ),
    );
  }
}
