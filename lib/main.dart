import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'meal_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://cewxkjgcejoqilwxskhi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNld3hramdjZWpvcWlsd3hza2hpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQyNDA0MzEsImV4cCI6MjA0OTgxNjQzMX0.o9GUHNqGPaFQIeVCKPow5cHuWLsVacoMBlk3H2Rg3eY',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Справочник продуктов',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const DailyMealsPage(),
    );
  }
}
