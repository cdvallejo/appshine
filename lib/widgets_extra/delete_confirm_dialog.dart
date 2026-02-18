import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Moment'),
      content: const Text(
        'This action cannot be undone. Are you sure you want to delete this moment?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () async {
            await onConfirm();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('DELETE', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
