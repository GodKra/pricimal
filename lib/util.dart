import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });
}

class GenericSearchBox<T extends Object> extends StatelessWidget {
  final List<T> items;
  final ValueChanged<T> onSelectItem;
  final String Function(T item) labelBuilder;
  final String Function(T item) trailingBuilder;
  final String hintText;

  const GenericSearchBox({
    super.key,
    required this.items,
    required this.onSelectItem,
    required this.labelBuilder,
    required this.trailingBuilder,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Expanded(
              child: Autocomplete<T>(
                displayStringForOption: labelBuilder,
                optionsBuilder: (TextEditingValue t) {
                  if (t.text.isEmpty) {
                    return items;
                  }
                  return items.where((T option) {
                    final label = labelBuilder(option).toLowerCase();
                    return label.contains(t.text.toLowerCase());
                  });
                },
                onSelected: (T selection) {
                  onSelectItem(selection);
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    onEditingComplete: onEditingComplete,
                    decoration: InputDecoration(
                      hintText: hintText,
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  );
                },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: ListView.separated(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final T option = options.elementAt(index);
                            return ListTile(
                              leading: Icon(Icons.add),
                              title: Text(
                                labelBuilder(option),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              trailing: Text(
                                trailingBuilder(option),
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              onTap: () {
                                onSelected(option);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}