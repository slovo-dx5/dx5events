import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

class ContactSaveTest extends StatefulWidget {
  const ContactSaveTest({super.key});

  @override
  State<ContactSaveTest> createState() => _ContactSaveTestState();
}

class _ContactSaveTestState extends State<ContactSaveTest> {
  bool isLoading = false;
  String statusMessage = "Ready to test";

  // Dummy contact data for testing
  final String testFirstName = "John";
  final String testLastName = "Doe";
  final String testPhone = "+1234567890";
  final String testEmail = "john.doe@example.com";
  final String testCompany = "Test Company Inc.";
  final String testRole = "Software Engineer";

  Future<void> testSaveContact() async {
    setState(() {
      isLoading = true;
      statusMessage = "Requesting permission...";
    });

    try {
      // Request permission
      final permission = await FlutterContacts.requestPermission();

      if (!permission) {
        setState(() {
          statusMessage = "❌ Permission denied";
          isLoading = false;
        });
        Fluttertoast.showToast(
          msg: "Please enable contacts permission in Settings",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.red,
        );
        return;
      }

      setState(() {
        statusMessage = "Permission granted. Creating contact...";
      });

      // Create contact
      final newContact = Contact(
        name: Name(first: testFirstName, last: testLastName),
        phones: [Phone(testPhone)],
        emails: [Email(testEmail)],
        organizations: [Organization(company: testCompany, title: testRole)],
      );

      setState(() {
        statusMessage = "Saving contact...";
      });

      // Save the contact
      await newContact.insert();

      setState(() {
        statusMessage = "✅ Contact saved successfully!";
        isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Contact saved! Check your Contacts app",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.green,
      );
    } catch (e) {
      setState(() {
        statusMessage = "❌ Error: ${e.toString()}";
        isLoading = false;
      });

      Fluttertoast.showToast(
        msg: "Failed to save contact: ${e.toString()}",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.red,
      );

      print("Contact save error: $e");
    }
  }

  Future<void> checkPermissionStatus() async {
    setState(() {
      statusMessage = "Checking permission status...";
    });

    try {
      final hasPermission = await FlutterContacts.requestPermission(readonly: true);
      setState(() {
        statusMessage = hasPermission
          ? "✅ Permission already granted"
          : "⚠️ Permission not granted";
      });
    } catch (e) {
      setState(() {
        statusMessage = "❌ Error checking permission: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Save Test'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Status Card
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Icon(Icons.info_outline, size: 40, color: Colors.blue),
                      const SizedBox(height: 10),
                      Text(
                        statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (isLoading) ...[
                        const SizedBox(height: 10),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
        
              // Dummy Contact Info
              const Text(
                'Test Contact Data:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.person, 'Name', '$testFirstName $testLastName'),
              _buildInfoRow(Icons.phone, 'Phone', testPhone),
              _buildInfoRow(Icons.email, 'Email', testEmail),
              _buildInfoRow(Icons.business, 'Company', testCompany),
              _buildInfoRow(Icons.work, 'Role', testRole),
        
              const SizedBox(height: 30),
        
              // Test Buttons
              ElevatedButton.icon(
                onPressed: isLoading ? null : checkPermissionStatus,
                icon: const Icon(Icons.security),
                label: const Text('Check Permission Status'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              ElevatedButton.icon(
                onPressed: isLoading ? null : testSaveContact,
                icon: const Icon(Icons.save),
                label: const Text('Save Test Contact'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
        
              const SizedBox(height: 30),
        
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Instructions:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 8),
                    Text('1. Check permission status first'),
                    Text('2. Tap "Save Test Contact"'),
                    Text('3. Grant permission if asked'),
                    Text('4. Check your Contacts app'),
                    Text('5. Look for "John Doe"'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
