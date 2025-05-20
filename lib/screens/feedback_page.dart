import 'package:dx5veevents/dioServices/dioPostService.dart';
import 'package:flutter/material.dart';

class FeedbackPage extends StatefulWidget {
  String attendeeName;
  String attendeeID;
  String eventID;
   FeedbackPage({Key? key,required this.attendeeID, required this.attendeeName,
    required this.eventID

  }) : super(key: key);

  @override
  _FeedbackPageState createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // List of items for user to select from
  final List<String> _items = [
    'Session',
    'Event Venue',
    'Lunch',
    'Speaker',
    'Other'
  ];

  // Selected item - initialized with the first item in the list
  String? _selectedItem;

  // Controllers for text fields
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _speakerNameController = TextEditingController();
  final TextEditingController _sessionTitleController = TextEditingController();
  final TextEditingController _otherNameController = TextEditingController();

  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Whether the form is currently submitting
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Set the default value to the first item in the list
    _selectedItem = _items.first;
  }

  @override
  void dispose() {
    // Clean up the controllers when the widget is disposed
    _commentController.dispose();
    _speakerNameController.dispose();
    _sessionTitleController.dispose();
    super.dispose();
  }

  // Check if additional fields should be shown
  bool get _showSpeakerField => _selectedItem == 'Speaker';
  bool get _showSessionField => _selectedItem == 'Session';
  bool get _showOtherField => _selectedItem == 'Other';

  Future<void> _submitFeedback() async {
    if (_formKey.currentState!.validate() && _selectedItem != null) {
      setState(() {
        _isSubmitting = true;
      });

      // Simulate API call with a delay
      await Future.delayed(const Duration(seconds: 2));

     await DioPostService().sendFeedback(body: {
       "subject":_selectedItem,
       "user_comments":_commentController.text,
       "attendee_name":widget.attendeeName,
       "attendee_id":widget.attendeeID,
       "event_id":widget.eventID,
       "speaker_name":_speakerNameController.text,
       "session_name":_sessionTitleController.text,
       "other_name":_otherNameController.text,

     });

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Feedback submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Reset the form
        _selectedItem = _items.first;
        _commentController.clear();
        _speakerNameController.clear();
        _sessionTitleController.clear();
      }
    } else if (_selectedItem == null) {
      // Show error if no item selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an item to give feedback on'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select an item to give feedback on:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Item selection dropdown
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedItem,
                      isExpanded: true,
                      hint: const Text('Select an item'),
                      icon: const Icon(Icons.arrow_drop_down),
                      elevation: 16,
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedItem = newValue;
                        });
                      },
                      items: _items.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Conditional Speaker Name field
                if (_showSpeakerField) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Speaker Name:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _speakerNameController,
                    decoration: InputDecoration(
                      hintText: 'Enter speaker name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (_showSpeakerField && (value == null || value.trim().isEmpty)) {
                        return 'Please enter the speaker name';
                      }
                      return null;
                    },
                  ),
                ],
                if (_showOtherField) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Other:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _otherNameController,
                    decoration: InputDecoration(
                      hintText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (_showOtherField && (value == null || value.trim().isEmpty)) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                ],

                // Conditional Session Title field
                if (_showSessionField) ...[
                  const SizedBox(height: 20),
                  const Text(
                    'Session Title:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _sessionTitleController,
                    decoration: InputDecoration(
                      hintText: 'Enter session title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                      ),
                    ),
                    validator: (value) {
                      if (_showSessionField && (value == null || value.trim().isEmpty)) {
                        return 'Please enter the session title';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 20),

                const Text(
                  'Your feedback:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                // Feedback text field
                TextFormField(
                  controller: _commentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Please share your thoughts or suggestions...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your feedback';
                    }
                    if (value.trim().length < 10) {
                      return 'Feedback must be at least 10 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Submit button
                Center(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitFeedback,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 2,
                    ),
                    child: _isSubmitting
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Submitting...'),
                      ],
                    )
                        : const Text(
                      'Submit Feedback',
                      style: TextStyle(fontSize: 16,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}