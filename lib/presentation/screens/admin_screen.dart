import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Control Panel'),
        backgroundColor: Colors.indigo,
      ),
      // StreamBuilder listens to real-time updates from the 'users' collection
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          // 1. Connection check: The snapshot tells us if we are still waiting for the "package"
          // Show a progress indicator while connecting to the stream
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // 2. Data check: The snapshot is "crushed" (updated) with either data or an error.
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No registered users found.'));
          }

          // 3. Final State: If we reach here, the snapshot was successfully updated with the real-time list of users from Firestore.
          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              // Extract data from the current document
              final userData = users[index].data() as Map<String, dynamic>;
              
              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.indigo,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(userData['email'] ?? 'No email provided'),
                subtitle: Text('Admin status: ${userData['isAdmin'] ?? false}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Future task: Add user details or management options
                },
              );
            },
          );
        },
      ),
    );
  }
}