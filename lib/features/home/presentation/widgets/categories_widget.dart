import 'package:flutter/material.dart';

class CategoriesWidget extends StatelessWidget {
  final String? selectedCategory;
  final Function(String)? onCategorySelected;

  const CategoriesWidget({
    super.key,
    this.selectedCategory,
    this.onCategorySelected,
  });

  static final List<Map<String, dynamic>> categories = [
    {'name': 'Books', 'icon': Icons.book_outlined},
    {'name': 'Furniture', 'icon': Icons.chair_outlined},
    {'name': 'Electronics', 'icon': Icons.devices_other_outlined},
    {'name': 'Kitchen', 'icon': Icons.kitchen_outlined},
    {'name': 'Clothes', 'icon': Icons.checkroom_outlined},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category['name']?.toString() ?? '';
    final isSelected = selectedCategory != null && selectedCategory!.toLowerCase() == name.toLowerCase();

    return Semantics(
      button: true,
      label: isSelected ? 'Category $name (Selected)' : 'Category $name',
      child: GestureDetector(
        onTap: () {
          if (onCategorySelected != null) {
            onCategorySelected!(name);
          }
        },
        child: SizedBox(
          width: 60, // Fixed width so items align nicely
          child: ExcludeSemantics(
            child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF0F4C3A) : const Color(0xFFE8EBE9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                category['icon'] as IconData,
                size: 24,
                color: isSelected ? Colors.white : const Color(0xFF1A1C1E),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? const Color(0xFF0F4C3A) : const Color(0xFF1A1C1E),
              ),
            ),
          ],
        ),
      ),
      ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Explore Categories',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1C1E),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: categories
                .map(
                  (c) => Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: _buildCategoryItem(c),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
