import 'package:appshine/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return AlertDialog(
      title: Text(loc.translate('deleteConfirmTitle')),
      content: Text(loc.translate('deleteConfirmMessage')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.translate('cancel')),
        ),
        TextButton(
          onPressed: () async {
            await onConfirm();
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(loc.translate('delete'), style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
