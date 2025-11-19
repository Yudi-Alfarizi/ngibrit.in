import 'package:flutter/material.dart';

class MultiLineDropdown extends StatefulWidget {
  final String? value;
  final List<String> items;
  final String hint;
  final Function(String) onSelected;
  final Widget icon; // 👈 sekarang icon fleksibel, bukan image asset

  const MultiLineDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.onSelected,
    required this.icon,
  });

  @override
  State<MultiLineDropdown> createState() => _MultiLineDropdownState();
}

class _MultiLineDropdownState extends State<MultiLineDropdown> {
  bool isFocused = false;

  void openDropdown() {
    setState(() => isFocused = true);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, controller) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade400,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    widget.hint,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff070623),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: widget.items.length,
                      itemBuilder: (context, index) {
                        final item = widget.items[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: Colors.white,
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                Navigator.pop(context);
                                widget.onSelected(item);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle_outline,
                                      size: 22,
                                      color: Color(0xff4A1DFF),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xff070623),
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      setState(() => isFocused = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: openDropdown,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isFocused ? const Color(0xff4A1DFF) : Colors.grey.shade300,
            width: isFocused ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            widget.icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.value ?? widget.hint,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  color: widget.value != null
                      ? const Color(0xff070623)
                      : Color(0xff838384),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Color(0xff070623),
            ),
          ],
        ),
      ),
    );
  }
}
