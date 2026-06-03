import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart' as pkg_provider;
import '../../constants/constants.dart';
import '../../features/request_detail/mock/request_mock_data.dart';
import '../../models/request_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart' as app_auth;
import '../../widgets/role_pill.dart';
import '../../widgets/role_switch_sheet.dart';
import 'requester_controller.dart';

class RequesterHomeScreen extends ConsumerWidget {
  const RequesterHomeScreen({super.key});

  void _showRoleSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => RoleSwitchSheet(
        currentRole: RoleType.requester,
        onRoleSelected: (role) async {
          if (role == RoleType.volunteer) {
            try {
              await context
                  .read<app_auth.AuthProvider>()
                  .switchRole(UserRole.volunteer);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Switch failed: $e')),
                );
                return;
              }
            }
            if (context.mounted) context.go(AppRoutes.home);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).value?.uid ?? '';
    final requestsAsync = ref.watch(myRequestsProvider(uid));
    final userName = context.read<app_auth.AuthProvider>().userModel?.name ?? 'Requester';

    return Scaffold(
      backgroundColor: kBgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: kBgColor,
            floating: true,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: kCardColor,
                  child: const Icon(Icons.person, color: Colors.white70, size: 20),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'REQUESTER MODE',
                      style: TextStyle(
                          color: kTextSecondary,
                          fontSize: 10,
                          letterSpacing: 1.0),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: Colors.white70),
                onPressed: () => context.go(AppRoutes.notifications),
              ),
              IconButton(
                icon: const Icon(Icons.swap_horiz, color: Colors.white70),
                tooltip: 'Switch role',
                onPressed: () => _showRoleSheet(context),
              ),
              _RequesterBadge(),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _HeroCTACard(onTap: () => context.pushNamed('new-request')),
                const SizedBox(height: 24),
                _QuickPostSection(ref: ref, context: context),
                const SizedBox(height: 24),
                _ActiveRequestsSection(requestsAsync: requestsAsync),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequesterBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.shield_outlined, color: kUrgentColor, size: 13),
          const SizedBox(width: 4),
          Text(
            'REQUESTER',
            style: TextStyle(
                color: kUrgentColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

class _HeroCTACard extends StatelessWidget {
  final VoidCallback onTap;
  const _HeroCTACard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE24B4A), Color(0xFFB83534)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white24,
              child: const Icon(Icons.person, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I need help now',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Post in 3 taps · 147 volunteers within 2 km',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _QuickPostSection extends StatelessWidget {
  final WidgetRef ref;
  final BuildContext context;
  const _QuickPostSection({required this.ref, required this.context});

  @override
  Widget build(BuildContext _) {
    final items = [
      (RequestType.medical, Icons.medical_services_outlined, 'Medical',
          'Injury, breathing', kCriticalColor),
      (RequestType.water, Icons.water_drop_outlined, 'Water',
          'Drinking, hygiene', kUrgentColor),
      (RequestType.shelter, Icons.home_outlined, 'Shelter', 'For tonight',
          const Color(0xFFEF7F27)),
      (RequestType.transport, Icons.directions_bus_outlined, 'Ride',
          'Hospital, evac', kPrimaryBlue),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'QUICK POST',
              style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0),
            ),
            const SizedBox(width: 8),
            Text(
              '· One tap · uses your current location',
              style: TextStyle(color: kTextSecondary, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.4,
          children: items
              .map((item) => _QuickPostCard(
                    type: item.$1,
                    icon: item.$2,
                    label: item.$3,
                    subtitle: item.$4,
                    color: item.$5,
                    onTap: () {
                      ref
                          .read(requesterControllerProvider.notifier)
                          .selectCategory(item.$1);
                      context.pushNamed('new-request');
                    },
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _QuickPostCard extends StatelessWidget {
  final RequestType type;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickPostCard({
    required this.type,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: kCardColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(color: kTextSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRequestsSection extends StatelessWidget {
  final AsyncValue<List<RequestModel>> requestsAsync;
  const _ActiveRequestsSection({required this.requestsAsync});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        requestsAsync.when(
          data: (requests) => Row(
            children: [
              Text(
                'ACTIVE REQUESTS',
                style: TextStyle(
                    color: kTextSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: kCardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${requests.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          loading: () => Text('ACTIVE REQUESTS',
              style: TextStyle(color: kTextSecondary, fontSize: 11)),
          error: (err, st) => Text('ACTIVE REQUESTS',
              style: TextStyle(color: kTextSecondary, fontSize: 11)),
        ),
        const SizedBox(height: 10),
        requestsAsync.when(
          data: (requests) => requests.isEmpty
              ? _EmptyRequests()
              : Column(
                  children:
                      requests.map((r) => _RequestCard(request: r)).toList(),
                ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: kPrimaryBlue)),
          error: (e, _) => Text('Error: $e',
              style: TextStyle(color: kCriticalColor, fontSize: 11)),
        ),
      ],
    );
  }
}

class _EmptyRequests extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No active requests',
        textAlign: TextAlign.center,
        style: TextStyle(color: kTextSecondary, fontSize: 14),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final RequestModel request;
  const _RequestCard({required this.request});

  RequestDetailData _toDetailData() => RequestDetailData(
        id: request.id,
        category: request.requestType.name,
        urgencyLevel: request.urgencyLevel,
        title: request.title,
        distanceKm: null,
        minutesAgo: DateTime.now().difference(request.createdAt).inMinutes,
        postedAt: request.createdAt,
        requesterName: request.isAnonymous ? 'Anonymous'
            : (request.requesterName.isNotEmpty ? request.requesterName : 'You'),
        requesterLocation: request.location.address,
        isAnonymous: request.isAnonymous,
        isVerified: false,
        description: request.description,
        skillsNeeded: const [],
        lat: request.location.coordinates.latitude,
        lng: request.location.coordinates.longitude,
        createdBy: request.createdBy,
        requestStatus: request.status,
      );

  // Urgency: color + bg
  static const _urgencyColors = {
    UrgencyLevel.critical: (Color(0xFFE24B4A), Color(0xFF3D1A1A)),
    UrgencyLevel.urgent:   (Color(0xFFEF9F27), Color(0xFF2D1F08)),
    UrgencyLevel.general:  (Color(0xFF639922), Color(0xFF1A2D0F)),
  };

  // Status: color + bg
  static const _statusColors = {
    RequestStatus.matched:   (Color(0xFF4CAF70), Color(0xFF1A2D1A)),
    RequestStatus.waiting:   (Color(0xFF888888), Color(0xFF2A2A2A)),
    RequestStatus.completed: (Color(0xFF888888), Color(0xFF2A2A2A)),
  };

  @override
  Widget build(BuildContext context) {
    final (urgencyFg, urgencyBg) =
        _urgencyColors[request.urgencyLevel] ?? (kCriticalColor, const Color(0xFF3D1A1A));
    final (statusFg, statusBg) =
        _statusColors[request.status] ?? (Colors.grey, const Color(0xFF2A2A2A));

    return GestureDetector(
      onTap: () => context.push(
        '${AppRoutes.requestDetail}/${request.id}',
        extra: {'request': _toDetailData(), 'showActions': false},
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1 — badges + timestamp
          Row(
            children: [
              _Badge(
                '● ${request.urgencyLevel.name.toUpperCase()}',
                urgencyFg,
                urgencyBg,
              ),
              const SizedBox(width: 6),
              _Badge(
                '● ${request.status.name.toUpperCase()}',
                statusFg,
                statusBg,
              ),
              const Spacer(),
              Text(
                _timeAgo(request.createdAt),
                style: const TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Row 2 — title
          Text(
            request.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          // Row 3 — status-dependent
          if (request.status == RequestStatus.matched)
            _MatchedRow(
              assignedCount: request.assignedVolunteerIds.length,
              volunteerNames: request.assignedVolunteerNames,
            )
          else if (request.status == RequestStatus.waiting)
            _WaitingRow(),
        ],
      ),
    ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Posted ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Posted ${diff.inHours} hr ago';
    return 'Posted ${diff.inDays}d ago';
  }
}

class _MatchedRow extends StatelessWidget {
  final int assignedCount;
  final List<String> volunteerNames;
  const _MatchedRow({required this.assignedCount, this.volunteerNames = const []});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar stack
        SizedBox(
          width: assignedCount > 1 ? 44.0 : 24.0,
          height: 24,
          child: Stack(
            children: List.generate(
              assignedCount.clamp(0, 3),
              (i) => Positioned(
                left: i * 14.0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF4CAF70),
                  child: Text(
                    String.fromCharCode(65 + i),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                volunteerNames.isNotEmpty
                    ? volunteerNames.first
                    : 'Volunteer responding',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                assignedCount > 1
                    ? '+${assignedCount - 1} more responding'
                    : 'On the way',
                style: const TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right, color: kTextSecondary, size: 18),
      ],
    );
  }
}

class _WaitingRow extends StatelessWidget {
  const _WaitingRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.circle, color: Color(0xFF888888), size: 8),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Reaching nearby volunteers...',
            style: TextStyle(color: kTextSecondary, fontSize: 12),
          ),
        ),
        GestureDetector(
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF444444)),
            ),
            child: const Text(
              'Boost',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  const _Badge(this.label, this.fg, this.bg);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
