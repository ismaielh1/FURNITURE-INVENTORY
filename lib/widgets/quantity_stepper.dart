import 'package:flutter/material.dart';

class QuantityStepper extends StatefulWidget {
  final int quantity;
  final Function(int) onConfirm;
  const QuantityStepper({
    Key? key,
    required this.quantity,
    required this.onConfirm,
  }) : super(key: key);
  @override
  _QuantityStepperState createState() => _QuantityStepperState();
}

class _QuantityStepperState extends State<QuantityStepper> {
  bool _isEditing = false;
  int? _pendingQuantity;

  @override
  void didUpdateWidget(covariant QuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.quantity != oldWidget.quantity) {
      _isEditing = false;
      _pendingQuantity = null;
    }
  }

  void _enterEditMode(int change) {
    if (widget.quantity + change < 0) return;
    setState(() {
      _pendingQuantity = widget.quantity + change;
      _isEditing = true;
    });
  }

  void _cancelEdit() => setState(() {
        _isEditing = false;
        _pendingQuantity = null;
      });

  void _confirmEdit() {
    if (_pendingQuantity != null) {
      widget.onConfirm(_pendingQuantity!);
    }
    setState(() {
      _isEditing = false;
      _pendingQuantity = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isEditing) {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove, size: 18),
              onPressed: () => _enterEditMode(-1),
            ),
            Text(
              widget.quantity.toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 18),
              onPressed: () => _enterEditMode(1),
            ),
          ],
        ),
      );
    } else {
      return Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.amber),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.close,
                size: 20,
                color: Colors.red.shade700,
              ),
              onPressed: _cancelEdit,
            ),
            Text(
              _pendingQuantity.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.check,
                size: 20,
                color: Colors.green.shade700,
              ),
              onPressed: _confirmEdit,
            ),
          ],
        ),
      );
    }
  }
}
