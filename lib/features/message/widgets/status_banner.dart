import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';

const _kDotColor = Color(0xFFE84935);

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, this.etaMinutes});

  final int? etaMinutes;

  @override
  Widget build(BuildContext context) {
    final eta = etaMinutes != null ? ' · ETA $etaMinutes min' : '';
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: _kDotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Request active · Volunteer assigned$eta',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
