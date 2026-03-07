import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatefulWidget {
  final Future<void> Function() onConfirm;

  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  State<DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<DeleteConfirmDialog> {
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(loc.translate('deleteConfirmTitle')),
      content: Text(loc.translate('deleteConfirmMessage')),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.pop(context),
          child: Text(loc.translate('cancel')),
        ),
        TextButton(
          onPressed: _isDeleting ? null : () async {
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
