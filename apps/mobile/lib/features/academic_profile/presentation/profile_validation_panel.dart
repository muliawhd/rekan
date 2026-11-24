import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'profile_controller.dart';
import '../../../core/network/laravel_api.dart';
import 'development_profile_validation.dart';

/// Embedded only in the debug auth harness; no onboarding UI.
class ProfileValidationPanel extends StatefulWidget {
  const ProfileValidationPanel({super.key, required this.controller});
  final ProfileController controller;
  @override
  State<ProfileValidationPanel> createState() => _ProfileValidationPanelState();
}

class _ProfileValidationPanelState extends State<ProfileValidationPanel> {
  String? _roundTrip;
  bool _validating = false;
  Future<void> _roundTripWithApproval() async {
    if (!kDebugMode ||
        _validating ||
        widget.controller.status != ProfileStatus.empty) {
      return;
    }
    setState(() {
      _validating = true;
      _roundTrip = null;
    });
    var writeAttempted = false;
    try {
      final validation = DevelopmentProfileValidation(
        widget.controller.repository,
      );
      final approval = await validation.prepare();
      if (!mounted) return;
      final approved = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Approve development profile PUT?'),
          content: SingleChildScrollView(
            child: Text(
              'Confirm this is the approved second development account.\nTarget UUID: ${approval.userId}\nExact dummy payload:\n${const JsonEncoder.withIndent('  ').convert(approval.input.toJson())}\nExisting non-empty data will be rejected.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Approve PUT'),
            ),
          ],
        ),
      );
      if (!mounted || approved != true) {
        return;
      }
      writeAttempted = true;
      final matches = await validation.execute(approval);
      await widget.controller.load();
      validation.ensureCurrent(approval);
      if (!mounted) return;
      setState(
        () => _roundTrip = matches
            ? 'PASS: submitted dummy values match PUT and GET.'
            : 'FAIL: persisted values differ from the submitted dummy payload. No rollback attempted.',
      );
    } catch (error) {
      widget.controller.clear();
      if (mounted) {
        setState(
          () => _roundTrip =
              'FAIL: ${error is ApiFailure ? error.message : 'Validation could not complete.'} '
              '${writeAttempted ? 'A write may have completed. Reload to inspect; no automatic rollback or retry.' : 'No PUT sent.'}',
        );
      }
    } finally {
      if (mounted) setState(() => _validating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return const SizedBox.shrink();
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final busy = _validating || controller.status == ProfileStatus.loading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Development academic profile validation'),
            Text('Profile state: ${controller.status.name}'),
            if (controller.profile != null)
              Text('Profile UUID: ${controller.profile!.userId}'),
            if (controller.failure != null) Text(controller.failure!.message),
            if (controller.status == ProfileStatus.loading)
              const LinearProgressIndicator(),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () {
                      setState(() => _roundTrip = null);
                      controller.load();
                    },
              child: const Text('Load academic profile (GET)'),
            ),
            ElevatedButton(
              onPressed: busy || controller.status != ProfileStatus.empty
                  ? null
                  : _roundTripWithApproval,
              child: const Text('Validate PUT / GET (approval required)'),
            ),
            if (_roundTrip != null) Text(_roundTrip!),
          ],
        );
      },
    );
  }
}
