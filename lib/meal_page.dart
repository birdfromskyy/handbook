import 'package:flutter/material.dart';
import 'product_selection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class Meal {
  String name;
  List<Map<String, dynamic>> products;

  Meal({required this.name, this.products = const []});

  Map<String, dynamic> toJson() => {
        'name': name,
        'products': products,
      };

  static Meal fromJson(Map<String, dynamic> json) => Meal(
        name: json['name'],
        products: List<Map<String, dynamic>>.from(json['products']),
      );
}

class MealEditPage extends StatefulWidget {
  final Meal meal;
  final VoidCallback onSave;

  const MealEditPage({super.key, required this.meal, required this.onSave});

  @override
  _MealEditPageState createState() => _MealEditPageState();
}

class _MealEditPageState extends State<MealEditPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Редактирование: ${widget.meal.name}'),
      ),
      body: ListView.builder(
        itemCount: widget.meal.products.length,
        itemBuilder: (context, index) {
          final product = widget.meal.products[index];
          final grams = product['grams'] ?? 100;
          final factor = grams / 100;
          final calories = (product['calories'] ?? 0) * factor;
          final proteins = (product['proteins'] ?? 0) * factor;
          final fats = (product['fats'] ?? 0) * factor;
          final carbs = (product['carbohydrates'] ?? 0) * factor;

          return ListTile(
            title: Text(product['name']),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Калории: ${_formatNumber(calories)}'),
                Text('Белки: ${_formatNumber(proteins)}'),
                Text('Жиры: ${_formatNumber(fats)}'),
                Text('Углеводы: ${_formatNumber(carbs)}'),
                Text('Граммы: $grams г'),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Граммы',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    setState(() {
                      product['grams'] = double.tryParse(value) ?? 100.0;
                    });
                    widget.onSave();
                  },
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  widget.meal.products.removeAt(index);
                });
                widget.onSave();
              },
            ),
          );
        },
      ),
    );
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2);
  }
}

class DailyMealsPage extends StatefulWidget {
  const DailyMealsPage({super.key});

  @override
  _DailyMealsPageState createState() => _DailyMealsPageState();
}

class _DailyMealsPageState extends State<DailyMealsPage> {
  DateTime _selectedDate = DateTime.now();
  List<Meal> _meals = [
    Meal(name: 'Завтрак'),
    Meal(name: 'Обед'),
    Meal(name: 'Полдник'),
    Meal(name: 'Ужин'),
  ];

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String? mealsJson = prefs.getString(_selectedDateKey());
    if (mealsJson != null) {
      final List<dynamic> mealsList = jsonDecode(mealsJson);
      setState(() {
        _meals = mealsList.map((meal) => Meal.fromJson(meal)).toList();
      });
    } else {
      setState(() {
        _meals = [
          Meal(name: 'Завтрак'),
          Meal(name: 'Обед'),
          Meal(name: 'Полдник'),
          Meal(name: 'Ужин'),
        ];
      });
    }
  }

  Future<void> _saveMeals() async {
    final prefs = await SharedPreferences.getInstance();
    final String mealsJson =
        jsonEncode(_meals.map((meal) => meal.toJson()).toList());
    await prefs.setString(_selectedDateKey(), mealsJson);
  }

  String _selectedDateKey() {
    return _selectedDate.toIso8601String().split('T').first;
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      _loadMeals();
    }
  }

  void _addProductToMeal(Meal meal) async {
    final selectedProducts = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductSelectionPage(),
      ),
    );

    if (selectedProducts != null) {
      setState(() {
        meal.products.addAll(selectedProducts);
      });
      _saveMeals();
    }
  }

  Map<String, double> _calculateNutrients(Meal meal) {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalFats = 0;
    double totalCarbs = 0;

    for (var product in meal.products) {
      final grams = product['grams'] ?? 100;
      final factor = grams / 100;
      totalCalories += (product['calories'] ?? 0) * factor;
      totalProteins += (product['proteins'] ?? 0) * factor;
      totalFats += (product['fats'] ?? 0) * factor;
      totalCarbs += (product['carbohydrates'] ?? 0) * factor;
    }

    return {
      'calories': totalCalories,
      'proteins': totalProteins,
      'fats': totalFats,
      'carbs': totalCarbs,
    };
  }

  Map<String, double> _calculateTotalNutrients() {
    double totalCalories = 0;
    double totalProteins = 0;
    double totalFats = 0;
    double totalCarbs = 0;

    for (var meal in _meals) {
      final nutrients = _calculateNutrients(meal);
      totalCalories += nutrients['calories']!;
      totalProteins += nutrients['proteins']!;
      totalFats += nutrients['fats']!;
      totalCarbs += nutrients['carbs']!;
    }

    return {
      'calories': totalCalories,
      'proteins': totalProteins,
      'fats': totalFats,
      'carbs': totalCarbs,
    };
  }

  String _formatNumber(double number) {
    return number.toStringAsFixed(number.truncateToDouble() == number ? 0 : 2);
  }

  @override
  Widget build(BuildContext context) {
    final totalNutrients = _calculateTotalNutrients();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Приемы пищи'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _meals.length,
              itemBuilder: (context, index) {
                final meal = _meals[index];
                final nutrients = _calculateNutrients(meal);
                return ListTile(
                  title: Text(meal.name),
                  subtitle:
                      Text('Калории: ${_formatNumber(nutrients['calories']!)}, '
                          'Белки: ${_formatNumber(nutrients['proteins']!)}, '
                          'Жиры: ${_formatNumber(nutrients['fats']!)}, '
                          'Углеводы: ${_formatNumber(nutrients['carbs']!)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => _addProductToMeal(meal),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MealEditPage(meal: meal, onSave: _saveMeals),
                      ),
                    ).then((_) {
                      setState(() {});
                    });
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Общий итог:',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Калории: ${_formatNumber(totalNutrients['calories']!)}'),
                Text('Белки: ${_formatNumber(totalNutrients['proteins']!)}'),
                Text('Жиры: ${_formatNumber(totalNutrients['fats']!)}'),
                Text('Углеводы: ${_formatNumber(totalNutrients['carbs']!)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
