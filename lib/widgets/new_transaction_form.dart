import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';

class NewTransactionForm extends StatefulWidget {
  final bool isEditing;
  final Transaction? existingTx;
  final void Function(String, double, DateTime, String) onSubmit;

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
  final descriptionController = TextEditingController();
  String selectedCategory = 'Groceries';
  DateTime selectedDate = DateTime.now();

  final List<String> _categories = [
    'Groceries', 'Food Deliveries', 'Coffee', 'Alcohol/Bars', 'Gas/Fuel', 'Public Transit',
    'Taxi/Uber', 'Car Maintenance', 'Rent/Mortgage', 'Utilities', 'Internet/Phone',
    'Outings', 'Subscriptions', 'Gaming', 'Gambling', 'Crypto/Shares', 'Clothing', 'Electronics',
    'Gifts', 'Fitness/Gym', 'Pharmacy', 'Personal Care',
    'Trips/Travel', 'Education', 'Pets', 'Other'
  ];

  void _showCategoryPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Category', textAlign: TextAlign.center),
        content: SizedBox(
          width: double.maxFinite,
          child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final style = Transaction.getCategoryStyle(cat);

              return InkWell(
                onTap: () {
                  setState(() => selectedCategory = cat);
                  Navigator.pop(ctx);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(style['icon'], color: style['color'], size: 32),
                    const SizedBox(height: 8),
                    Text(cat, style: const TextStyle(fontSize: 10), textAlign: TextAlign.center, overflow: TextOverflow.ellipsis),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.existingTx != null) {
      descriptionController.text = widget.existingTx!.description;
      amountController.text = widget.existingTx!.amount.toString();
      selectedCategory = widget.existingTx!.category;
      selectedDate = widget.existingTx!.date;
    }
  }

  void submitData() {
    String amountText = amountController.text.replaceAll(',', '.');
    final enteredAmount = double.tryParse(amountText);

    final enteredDescription = descriptionController.text;

    if(enteredDescription.isEmpty || enteredAmount == null || enteredAmount <= 0) return;

    widget.onSubmit(enteredDescription, enteredAmount, selectedDate, selectedCategory);
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

          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(hintText: 'Description', prefixIcon: Icon(Icons.edit_note)),
          ),
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

          InkWell(
            onTap: _showCategoryPicker,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              decoration: BoxDecoration(
                color: theme.inputDecorationTheme.fillColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  //Show the currently selected icon
                  Icon(Transaction.getCategoryStyle(selectedCategory)['icon'], color: Transaction.getCategoryStyle(selectedCategory)['color']),
                  const SizedBox(width: 15),
                  //Show the currently selected name
                  Expanded(child: Text(selectedCategory, style: const TextStyle(fontSize: 16))),
                  const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                ],
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