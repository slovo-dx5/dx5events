import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExternalLinkButton extends StatelessWidget {
  final String buttonText;
  final String url;
  final String siteName;
  final IconData? icon;

  const ExternalLinkButton({
    Key? key,
    required this.buttonText,
    required this.url,
    required this.siteName,
    this.icon,
  }) : super(key: key);

  Future<void> _launchURL(BuildContext context) async {
    final Uri uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Show error if URL can't be launched
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $siteName'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Future<void> _showConfirmationDialog(BuildContext context) async {
  //   return showDialog<void>(
  //     context: context,
  //     barrierDismissible: false, // User must tap a button to close the dialog
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         title: Row(
  //           children: [
  //             const Icon(Icons.open_in_new, color: Colors.blue),
  //             const SizedBox(width: 10),
  //             const Text('External Link'),
  //           ],
  //         ),
  //         content: SingleChildScrollView(
  //           child: ListBody(
  //             children: <Widget>[
  //               Text('You are about to leave this app and visit $siteName.'),
  //               const SizedBox(height: 10),
  //               const Text('Do you want to continue?'),
  //             ],
  //           ),
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancel'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           FilledButton(
  //             child: const Text('Continue'),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //               _launchURL(context);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon != null ? Icon(icon) : const Icon(Icons.link),
        const SizedBox(width: 8),
        Text(buttonText),
      ],
    );
  }
}

// Example usage:
class ExamplePage extends StatelessWidget {
  const ExamplePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('External Link Example'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Example 1: Basic usage
            const ExternalLinkButton(
              buttonText: 'Visit Our Website',
              url: 'https://www.residencetechnologies.com/home/resident_map/',
              siteName: 'Example.com',
            ),

            const SizedBox(height: 20),

            // Example 2: With custom icon
            const ExternalLinkButton(
              buttonText: 'Open Documentation',
              url: 'https://www.residencetechnologies.com/home/resident_map/',
              siteName: 'Flutter Documentation',
              icon: Icons.book,
            ),

            const SizedBox(height: 20),

            // Example 3: Within a Card
            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Need more information?',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Check out our support center for more details about this feature.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const ExternalLinkButton(
                      buttonText: 'Support Center',
                      url: 'https://www.residencetechnologies.com/home/resident_map/',
                      siteName: 'Support Center',
                      icon: Icons.help_outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}