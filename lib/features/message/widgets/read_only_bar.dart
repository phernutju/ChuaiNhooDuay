import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';

class ReadOnlyBar extends StatelessWidget {
  const ReadOnlyBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.lock_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 6),
              Text(
                'Request closed · messages are read-only',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
