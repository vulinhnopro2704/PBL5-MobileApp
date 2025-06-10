import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class TrashBinActionButtons extends StatelessWidget {
  final VoidCallback onReset;
  final bool isLoading;

  const TrashBinActionButtons({
    super.key,
    required this.onReset,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Actions',
              style: AppTheme.subheadingStyle.copyWith(fontSize: 16),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : onReset,
              icon:
                  isLoading
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      )
                      : const Icon(Icons.refresh),
              label: Text(isLoading ? 'Resetting...' : 'Reset Bin'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.resetBinButtonColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
