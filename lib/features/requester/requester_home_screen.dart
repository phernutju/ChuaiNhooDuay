import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../constants/constants.dart';
import '../../models/request_model.dart';
import 'requester_controller.dart';

class RequesterHomeScreen extends ConsumerWidget {
  const RequesterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final requestsAsync = ref.watch(myRequestsProvider(uid));

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
                    const Text(
                      'Your req...',
                      style: TextStyle(
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
                onPressed: () {},
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
          error: (e, _) => Text('Error loading requests',
              style: TextStyle(color: kCriticalColor)),
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

  @override
  Widget build(BuildContext context) {
    final urgencyColor = switch (request.urgencyLevel) {
      UrgencyLevel.critical => kCriticalColor,
      UrgencyLevel.urgent => kUrgentColor,
      UrgencyLevel.general => kGeneralColor,
    };
    final statusColor = switch (request.status) {
      RequestStatus.matched => kGeneralColor,
      RequestStatus.waiting => Colors.grey,
      RequestStatus.completed => Colors.grey,
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(request.urgencyLevel.name.toUpperCase(), urgencyColor),
              const SizedBox(width: 6),
              _Badge(request.status.name.toUpperCase(), statusColor),
              const Spacer(),
              Text(
                _timeAgo(request.createdAt),
                style: TextStyle(color: kTextSecondary, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            request.title,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500),
          ),
          if (request.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              request.description,
              style: TextStyle(color: kTextSecondary, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Posted ${diff.inMinutes} min ago';
    if (diff.inHours < 24) return 'Posted ${diff.inHours} hr ago';
    return 'Posted ${diff.inDays}d ago';
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha:0.15),
        border: Border.all(color: color.withValues(alpha:0.6)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4),
      ),
    );
  }
}
