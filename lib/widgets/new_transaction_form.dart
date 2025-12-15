import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class NewTransactionForm extends StatefulWidget {
  final bool isEditing;
  final Transaction? existingTx;
  final void Function(double, DateTime, String) onSubmit;

  const NewTransactionForm({
    super.key,
    required this.onSubmit,
    this.isEditing = false,
    this.existingTx
  });

  @override
  State<NewTransactionForm> createState() => _NewTransactionFormState();
}

class _NewTransactionFormState extends State<NewTransactionForm> {
  final amountController = TextEditingController();
  String selectedCategory = 'Food';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingTx != null) {
      amountController.text = widget.existingTx!.amount.toString();
      selectedCategory = widget.existingTx!.category;
      selectedDate = widget.existingTx!.date;
    }
  }

  void submitData() {
    final enteredAmount = double.tryParse(amountController.text);
    if(enteredAmount == null || enteredAmount <= 0) return;

    widget.onSubmit(enteredAmount, selectedDate, selectedCategory);
    Navigator.of(context).pop();
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) return;
      setState(() => selectedDate = pickedDate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
          const SizedBox(height: 20),
          Text(widget.isEditing ? "Edit Transaction" : "New Transaction", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          //Amount Input only
          TextField(
            controller: amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(hintText: 'Amount', prefixIcon: Icon(Icons.euro_symbol)),
          ),
          const SizedBox(height: 20),

          //Date Selection
          Row(
            children: [
              Expanded(child: Text("Date: ${DateFormat.yMd().format(selectedDate)}", style: const TextStyle(fontWeight: FontWeight.bold))),
              TextButton(
                  onPressed: _presentDatePicker,
                  child: const Text('Choose Date', style: TextStyle(fontWeight: FontWeight.bold))
              )
            ],
          ),
          const SizedBox(height: 20),

          //Simple Dropdown
          Text("Category", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            decoration: BoxDecoration(
              color: theme.inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down),
                items: ['Food', 'Shopping', 'Transport', 'Entertainment', 'Bills', 'Health', 'Other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedCategory = val!),
              ),
            ),
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: submitData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Text(widget.isEditing ? 'Save Changes' : 'Add Transaction', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}