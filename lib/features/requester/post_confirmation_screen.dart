import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/constants.dart';
import 'requester_controller.dart';

class PostConfirmationScreen extends ConsumerWidget {
  final int volunteerCount;
  const PostConfirmationScreen({super.key, required this.volunteerCount});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: kBgColor,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: const BoxDecoration(
                    color: kUrgentColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 60),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Request posted',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Volunteers within 2 km have been notified.\nYou\'ll get a response shortly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: kTextSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: kCardColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: kUrgentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$volunteerCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                height: 1),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'VOLUNTEERS NOTIFIED',
                        style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 11,
                            letterSpacing: 1.4,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ref.read(requesterControllerProvider.notifier).reset();
                      context.goNamed('requester-home');
                    },
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: const Text(
                      'View my requests',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kPrimaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
