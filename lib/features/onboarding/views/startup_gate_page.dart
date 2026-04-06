import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routes/app_routes.dart';
import '../service/onboarding_storage_service.dart';
import '../viewmodels/startup_gate_view_model.dart';

class StartupGatePage extends StatefulWidget {
  final OnboardingStorageService onboardingStorageService;

  const StartupGatePage({
    required this.onboardingStorageService,
    super.key,
  });

  @override
  State<StartupGatePage> createState() => _StartupGatePageState();
}

class _StartupGatePageState extends State<StartupGatePage> {
  late final StartupGateViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = StartupGateViewModel(
      onboardingStorageService: widget.onboardingStorageService,
    );
    _viewModel.addListener(_onViewModelUpdated);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelUpdated);
    _viewModel.dispose();
    super.dispose();
  }

  void _onViewModelUpdated() {
    if (!mounted) {
      return;
    }

    if (_viewModel.targetRoute == StartupRouteTarget.home) {
      context.go(AppRoutes.home);
      return;
    }

    if (_viewModel.targetRoute == StartupRouteTarget.onboarding) {
      context.goNamed('onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}


