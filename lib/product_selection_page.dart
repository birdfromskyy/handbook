import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductSelectionPage extends StatefulWidget {
  const ProductSelectionPage({super.key});

  @override
  _ProductSelectionPageState createState() => _ProductSelectionPageState();
}

class _ProductSelectionPageState extends State<ProductSelectionPage> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  List<Map<String, dynamic>> _selectedProducts = [];
  String _selectedCategory = 'Все';

  final List<String> _categories = [
    'Все',
    'Фрукты',
    'Овощи',
    'Молочные продукты',
    'Мясо и рыба',
    'Зерновые и бобовые'
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    try {
      final response = await Supabase.instance.client.from('products').select();
      setState(() {
        _products = List<Map<String, dynamic>>.from(response);
        _filteredProducts = _products;
      });
    } catch (e) {
      print('Error fetching products: $e');
    }
  }

  void _filterProductsByCategory(String category) {
    setState(() {
      if (category == 'Все') {
        _filteredProducts = _products;
      } else {
        _filteredProducts = _products
            .where((product) => product['category'] == category)
            .toList();
      }
    });
  }

  void _toggleProductSelection(Map<String, dynamic> product, double grams) {
    setState(() {
      final productWithGrams = {...product, 'grams': grams};
      if (_selectedProducts.any((p) => p['id'] == product['id'])) {
        _selectedProducts.removeWhere((p) => p['id'] == product['id']);
      } else {
        _selectedProducts.add(productWithGrams);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор продуктов'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.pop(context, _selectedProducts);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedCategory,
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                  _filterProductsByCategory(newValue);
                }
              },
              items: _categories.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredProducts.length,
              itemBuilder: (context, index) {
                final product = _filteredProducts[index];
                final isSelected =
                    _selectedProducts.any((p) => p['id'] == product['id']);
                double grams = 100.0;

                return ListTile(
                  title: Text(product['name']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Калории: ${product['calories']}'),
                      Text('Белки: ${product['proteins']} г'),
                      Text('Жиры: ${product['fats']} г'),
                      Text('Углеводы: ${product['carbohydrates']} г'),
                      if (isSelected)
                        Text(
                            'Добавлено: ${_selectedProducts.firstWhere((p) => p['id'] == product['id'])['grams']} г'),
                      TextField(
                        decoration: const InputDecoration(
                          labelText: 'Граммы',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          grams = double.tryParse(value) ?? 100.0;
                        },
                      ),
                    ],
                  ),
                  trailing: Icon(
                    isSelected
                        ? Icons.check_box
                        : Icons.check_box_outline_blank,
                  ),
                  onTap: () => _toggleProductSelection(product, grams),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
