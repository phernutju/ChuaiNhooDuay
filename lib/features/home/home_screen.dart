import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user_model.dart';
import '../../providers/providers.dart';
import '../shell/requester_shell.dart';
import '../shell/volunteer_shell.dart';

/// Role gate at [AppRoutes.home].
///
/// Watches the signed-in user's role and routes into the matching shell:
///  - [UserRole.volunteer] → [VolunteerShell] (bottom-nav volunteer interface)
///  - [UserRole.civilian]  → [RequesterShell] (placeholder for now)
///
/// Because it `watch`es [AuthProvider], switching role (via the role-switch
/// sheet, which calls [AuthProvider.switchRole]) rebuilds this widget and
/// swaps shells without a manual navigation.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().userModel?.role;
    if (role == UserRole.volunteer) return const VolunteerShell();
    return const RequesterShell();
  }
}
