import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(EarthquakeApp());
}

class EarthquakeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Earthquake App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: EarthquakeListScreen(),
    );
  }
}

class EarthquakeListScreen extends StatefulWidget {
  @override
  _EarthquakeListScreenState createState() => _EarthquakeListScreenState();
}

class _EarthquakeListScreenState extends State<EarthquakeListScreen> {
  late Future<List<EarthquakeEvent>?> _earthquakeData;
  Color _backgroundColor = Colors.white;

  @override
  void initState() {
    super.initState();
    _earthquakeData = fetchEarthquakeData();
    _loadBackgroundColor();
  }

  Future<List<EarthquakeEvent>?> fetchEarthquakeData() async {
    final url = Uri.parse('https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      final List<dynamic> features = data['features'];

      List<EarthquakeEvent> events = features.map((feature) {
        return EarthquakeEvent.fromJson(feature);
      }).toList();

      return events;
    } else {
      throw Exception('Error fetching earthquake data: ${response.statusCode}');
    }
  }

  void _loadBackgroundColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? backgroundColor = prefs.getString('backgroundColor');
    setState(() {
      _backgroundColor = backgroundColor != null ? Color(int.parse(backgroundColor)) : Colors.white;
    });
  }

  void _saveBackgroundColor(Color color) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('backgroundColor', color.value.toString());
    setState(() {
      _backgroundColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Earthquake List'),
      ),
      body: Container(
        color: _backgroundColor,
        child: FutureBuilder<List<EarthquakeEvent>?>(
          future: _earthquakeData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error fetching earthquake data: ${snapshot.error}'),
              );
            } else if (snapshot.hasData && snapshot.data != null) {
              final events = snapshot.data!;
              if (events.isEmpty) {
                return Center(
                  child: Text('No earthquake events found.'),
                );
              }
              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return ListTile(
                    title: Text('Magnitude: ${event.magnitude}'),
                    subtitle: Text('Location: ${event.location}'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EarthquakeDetailsScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              );
            } else {
              return Center(
                child: Text('No earthquake events found.'),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Change Background Color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                    pickerColor: _backgroundColor,
                    onColorChanged: (Color color) {
                      _saveBackgroundColor(color);
                    },
                  ),
                ),
              );
            },
          );
        },
        child: Icon(Icons.color_lens),
      ),
    );
  }
}

class EarthquakeEvent {
  final String date;
  final String details;
  final String location;
  final double magnitude;
  final String link;

  EarthquakeEvent({
    required this.date,
    required this.details,
    required this.location,
    required this.magnitude,
    required this.link,
  });

  factory EarthquakeEvent.fromJson(Map<String, dynamic> json) {
    final properties = json['properties'];
    return EarthquakeEvent(
      date: properties['time'].toString(),
      details: properties['title'].toString(),
      location: properties['place'].toString(),
      magnitude: properties['mag'].toDouble(),
      link: properties['url'].toString(),
    );
  }
}

class EarthquakeDetailsScreen extends StatelessWidget {
  final EarthquakeEvent event;

  EarthquakeDetailsScreen({required this.event});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Earthquake Details'),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Date: ${event.date}'),
            SizedBox(height: 8),
            Text('Details: ${event.details}'),
            SizedBox(height: 8),
            Text('Location: ${event.location}'),
            SizedBox(height: 8),
            Text('Magnitude: ${event.magnitude}'),
            SizedBox(height: 8),
            Text('Link: ${event.link}'),
          ],
        ),
      ),
    );
  }
}
