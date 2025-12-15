import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../providers/theme_provider.dart';
import '../widgets/new_transaction_form.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Transaction> allTransactions = [];
  List<Transaction> filteredTransactions = [];
  bool isLoading = true;
  DateTime currentMonth = DateTime.now();
  String selectedCategoryFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    final data = await DBHelper.instance.getTransactionsByMonth(currentMonth);
    setState(() {
      allTransactions = data;
      _applyCategoryFilter();
      isLoading = false;
    });
  }

  void _applyCategoryFilter() {
    if (selectedCategoryFilter == 'All') {
      filteredTransactions = List.from(allTransactions);
    } else {
      filteredTransactions = allTransactions.where((tx) => tx.category == selectedCategoryFilter).toList();
    }
  }

  void _changeMonth(int monthsToAdd) {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + monthsToAdd);
      selectedCategoryFilter = 'All';
    });
    _loadData();
  }

  //--- CRUD FUNCTIONS ---
  void addNewTransaction(double amount, DateTime date, String category) async {
    final style = Transaction.getCategoryStyle(category);
    final newTx = Transaction(
      amount: amount,
      date: date,
      category: category,
      icon: style['icon'],
      color: style['color'],
    );
    await DBHelper.instance.create(newTx);
    _loadData();
  }

  void updateTransaction(int id, double amount, DateTime date, String category) async {
    final style = Transaction.getCategoryStyle(category);
    final updatedTx = Transaction(
      id: id,
      amount: amount,
      date: date,
      category: category,
      icon: style['icon'],
      color: style['color'],
    );
    await DBHelper.instance.update(updatedTx);
    _loadData();
  }

  void deleteTransaction(int id) async {
    await DBHelper.instance.delete(id);
    _loadData();
  }

  void startEditTransaction(BuildContext ctx, Transaction tx) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: ctx,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: NewTransactionForm(
            isEditing: true,
            existingTx: tx,
            onSubmit: (amount, date, category) => updateTransaction(tx.id!, amount, date, category),
          ),
        );
      },
    );
  }

  void startAddNewTransaction(BuildContext ctx) {
    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      context: ctx,
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: NewTransactionForm(
            isEditing: false,
            onSubmit: (amount, date, category) => addNewTransaction(amount, date, category),
          ),
        );
      },
    );
  }

  double get totalSpending => filteredTransactions.fold(0.0, (sum, item) => sum + item.amount);

  Map<String, double> get dataMap {
    Map<String, double> data = {};
    for (var item in allTransactions) {
      data.update(item.category, (value) => value + item.amount, ifAbsent: () => item.amount);
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Provider.of<ThemeNotifier>(context).isDarkMode ? Icons.dark_mode : Icons.light_mode),
          onPressed: () => Provider.of<ThemeNotifier>(context, listen: false).toggleTheme(),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.arrow_left), onPressed: () => _changeMonth(-1)),
            Text(DateFormat('MMMM y').format(currentMonth), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            IconButton(icon: const Icon(Icons.arrow_right), onPressed: () => _changeMonth(1)),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            //--- CHART ---
            Container(
              height: 200,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))],
              ),
              child: allTransactions.isEmpty
                  ? const Center(child: Text("No expenses this month"))
                  : Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 0,
                            centerSpaceRadius: 50,
                            startDegreeOffset: -90,
                            sections: dataMap.entries.map((e) {
                              final color = allTransactions.firstWhere((tx) => tx.category == e.key).color;
                              final isSelected = selectedCategoryFilter == 'All' || selectedCategoryFilter == e.key;
                              return PieChartSectionData(
                                  color: color.withOpacity(isSelected ? 1 : 0.3),
                                  value: e.value,
                                  radius: isSelected ? 25 : 10,
                                  showTitle: false
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(selectedCategoryFilter == 'All' ? 'Total' : selectedCategoryFilter, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            Text('€${totalSpending.toInt()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            //--- FILTER CHIPS ---
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Food', 'Transport', 'Shopping', 'Entertainment', 'Bills', 'Health', 'Other'].map((cat) {
                  final isSelected = selectedCategoryFilter == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: Colors.black,
                      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                      backgroundColor: Colors.grey[200],
                      onSelected: (bool selected) {
                        if (selected) setState(() { selectedCategoryFilter = cat; _applyCategoryFilter(); });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 15),

            //--- SLIDER LIST (Edit/Delete) ---
            Expanded(
              child: filteredTransactions.isEmpty
                  ? Center(child: Text("No $selectedCategoryFilter expenses."))
                  : ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (ctx, index) {
                  final tx = filteredTransactions[index];

                  return Dismissible(
                    key: ValueKey(tx.id),

                    //1. SLIDE RIGHT (EDIT - Green)
                    background: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(15)),
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.only(left: 20),
                      child: const Icon(Icons.edit, color: Colors.white),
                    ),

                    //2. SLIDE LEFT (DELETE - Red)
                    secondaryBackground: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),

                    //3. LOGIC: Decide what to do based on swipe direction
                    confirmDismiss: (direction) async {
                      if (direction == DismissDirection.startToEnd) {
                        //Swiped Right -> EDIT
                        startEditTransaction(context, tx);
                        return false;
                      } else {
                        //Swiped Left -> DELETE
                        deleteTransaction(tx.id!);
                        return true;
                      }
                    },

                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: tx.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: Icon(tx.icon, color: tx.color),
                        ),
                        title: Text(tx.category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(DateFormat('MMM d, y').format(tx.date), style: theme.textTheme.bodySmall),
                        trailing: Text('€${tx.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 14)),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => startAddNewTransaction(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_circle_outline),
        label: const Text("Add"),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}