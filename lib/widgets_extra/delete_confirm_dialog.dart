import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// A confirmation dialog for delete operations.
///
/// This dialog displays a confirmation message and provides options to cancel or confirm the deletion.
class DeleteConfirmDialog extends StatefulWidget {
  /// The async callback function invoked when the user confirms the deletion.
  final Future<void> Function() onConfirm;

  /// Creates a new [DeleteConfirmDialog].
  ///
  /// The [onConfirm] parameter is required and should be an async function that performs
  /// the deletion operation.
  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

/// State class for [DeleteConfirmDialog].
///
/// Manages the loading state during the deletion operation and handles user interactions.
class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  /// A boolean flag to indicate whether the deletion operation is currently in progress.
  bool _isDeleting = false;

  /// Builds the confirmation dialog with localized content and action buttons.
  ///
  /// Returns an [AlertDialog] with:
  /// - A cancel button that closes the dialog without performing the deletion
  /// - A delete button that executes [widget.onConfirm] and displays a loading indicator during the operation
  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(loc.translate('deleteConfirmTitle')),
      content: Text(loc.translate('deleteConfirmMessage')),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context), // Disable cancel button while deleting
          child: Text(loc.translate('cancel')),
        ),
        TextButton(
          onPressed: _isDeleting ? null : () async { // Disable delete button while deleting
            setState(() => _isDeleting = true);
            await widget.onConfirm();
            if (context.mounted) Navigator.pop(context);
          },
          child: _isDeleting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(loc.translate('delete'), style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
