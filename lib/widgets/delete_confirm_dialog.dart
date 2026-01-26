import 'package:flutter/material.dart';

class DeleteConfirmDialog extends StatelessWidget {
  final Future<void> Function() onConfirm;

  const DeleteConfirmDialog({super.key, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Eliminar este Momento?'),
      content: const Text(
        'Esta acción borrará el Momento de forma permanente.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
        TextButton(
          onPressed: () async {
            await onConfirm();
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('BORRAR', style: TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
