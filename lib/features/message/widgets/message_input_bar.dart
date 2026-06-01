import 'package:flutter/material.dart';
import 'package:we_are_ready/constants/constants.dart';

const _kSendColor = Color(0xFFE84935);

class MessageInputBar extends StatelessWidget {
  const MessageInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.isSending,
    this.onCameraPressed,
    this.onLocationPressed,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;
  final VoidCallback? onCameraPressed;
  final VoidCallback? onLocationPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 6, 8, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt_outlined),
                color: AppColors.textSecondary,
                onPressed: onCameraPressed,
              ),
              IconButton(
                icon: const Icon(Icons.location_on_outlined),
                color: AppColors.textSecondary,
                onPressed: onLocationPressed,
              ),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(maxHeight: 120),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: TextField(
                    controller: controller,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: AppColors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    keyboardAppearance: Brightness.dark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _SendButton(isSending: isSending, onTap: onSend),
            ],
          ),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  const _SendButton({required this.isSending, required this.onTap});

  final bool isSending;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSending
              ? _kSendColor.withValues(alpha: 0.5)
              : _kSendColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: isSending
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.arrow_upward, color: Colors.white, size: 20),
      ),
    );
  }
}
