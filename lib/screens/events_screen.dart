import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    fetchEvents();
  }

  Future<void> fetchEvents() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('notification')
          .orderBy('date')
          .get();

      setState(() {
        events = snapshot.docs
            .map((doc) => doc.data())
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching events: $e');
      setState(() {
        isLoading = false;
        events = [];
      });
    }
  }

  void showEventDetails(Map<String, dynamic> event) {
    final title = event['title'] ?? 'No Title';
    final subject = event['subject'] ?? 'No Subject';
    final date = event['date'] ?? 'No Date';
    final description = event['description'] ?? 'No Description';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text("Subject: $subject", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Date: $date", style: const TextStyle(fontSize: 16)),
                  const Divider(height: 24),
                  Text(description,
                      style: const TextStyle(fontSize: 16, height: 1.5)),

                  if (_containsURL(description))
                    TextButton.icon(
                      icon: const Icon(Icons.open_in_browser),
                      label: const Text("Open Link"),
                      onPressed: () => _launchFirstURL(description),
                    ),

                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  bool _containsURL(String text) {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)');
    return urlPattern.hasMatch(text);
  }

  Future<void> _launchFirstURL(String text) async {
    final urlPattern = RegExp(r'(https?:\/\/[^\s]+)');
    final match = urlPattern.firstMatch(text);
    if (match != null) {
      final url = Uri.parse(match.group(0)!);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Upcoming Events')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(
        child: Text(
          'You will be updated soon.',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              title: Text(event['title'] ?? 'Untitled'),
              subtitle: Text(event['subject'] ?? ''),
              trailing: Text(event['date'] ?? ''),
              onTap: () => showEventDetails(event),
            ),
          );
        },
      ),
    );
  }
}
