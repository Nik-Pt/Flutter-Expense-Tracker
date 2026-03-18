import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../services/db_helper.dart';
import '../providers/theme_provider.dart';
import '../widgets/new_transaction_form.dart';
import '../services/data_sync_service.dart';

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
  final List<String> _allCategories =  ['Groceries', 'Food Deliveries', 'Coffee', 'Alcohol/Bars', 'Gas/Fuel', 'Public Transit',
    'Taxi/Uber', 'Car Maintenance', 'Rent/Mortgage', 'Utilities', 'Internet/Phone',
    'Outings', 'Subscriptions', 'Gaming', 'Gambling', 'Crypto/Shares', 'Clothing', 'Electronics',
    'Gifts', 'Fitness/Gym', 'Pharmacy', 'Personal Care',
    'Trips/Travel', 'Education', 'Pets', 'Other'];


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

  void _showCategoryFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter by Category', textAlign: TextAlign.center),
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
            itemCount: _allCategories.length,
            itemBuilder: (ctx, i) {
              final cat = _allCategories[i];
              final style = Transaction.getCategoryStyle(cat);

              return InkWell(
                onTap: () {
                  setState(() {
                    selectedCategoryFilter = cat;
                    _applyCategoryFilter();
                  });
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

  //--- CRUD FUNCTIONS ---
  void addNewTransaction(String description, double amount, DateTime date, String category) async {
    final style = Transaction.getCategoryStyle(category);
    final newTx = Transaction(
      description: description,
      amount: amount,
      date: date,
      category: category,
      icon: style['icon'],
      color: style['color'],
    );
    await DBHelper.instance.create(newTx);
    _loadData();
  }

  void updateTransaction(int id, String description, double amount, DateTime date, String category) async {
    final style = Transaction.getCategoryStyle(category);
    final updatedTx = Transaction(
      id: id,
      description: description,
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
            onSubmit: (description, amount, date, category) => updateTransaction(tx.id!, description, amount, date, category),
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
            onSubmit: (description, amount, date, category) => addNewTransaction(description, amount, date, category),
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
        scrolledUnderElevation: 0,
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

        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.import_export),
            onSelected: (value) async {
              if (value == 'export_json') await DataSyncService.exportToJSON();
              if (value == 'export_csv') await DataSyncService.exportToCSV();
              if (value == 'export_xlsx') await DataSyncService.exportToExcel();

              if (value.startsWith('import_')) {
                if (value == 'import_json') await DataSyncService.importFromJSON();
                if (value == 'import_csv') await DataSyncService.importFromCSV();
                if (value == 'import_xlsx') await DataSyncService.importFromExcel();

                _loadData();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                enabled: false,
                child: Text('EXPORT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'export_csv', child: Text('Export as CSV')),
              const PopupMenuItem(value: 'export_json', child: Text('Export as JSON')),
              const PopupMenuItem(value: 'export_xlsx', child: Text('Export as Excel')),

              const PopupMenuDivider(),

              const PopupMenuItem(
                enabled: false,
                child: Text('IMPORT', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              const PopupMenuItem(value: 'import_csv', child: Text('Import CSV Backup')),
              const PopupMenuItem(value: 'import_json', child: Text('Import JSON Backup')),
              const PopupMenuItem(value: 'import_xlsx', child: Text('Import Excel Backup')),
            ],
          ),
        ],
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
                            centerSpaceRadius: 60,
                            startDegreeOffset: -90,
                            sections: dataMap.entries.map((e) {
                              final color = allTransactions.firstWhere((tx) => tx.category == e.key).color;
                              final isSelected = selectedCategoryFilter == 'All' || selectedCategoryFilter == e.key;
                              return PieChartSectionData(
                                  color: color.withOpacity(isSelected ? 1 : 0.3),
                                  value: e.value,
                                  radius: isSelected ? 30 : 20,
                                  showTitle: false
                              );
                            }).toList(),
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(selectedCategoryFilter == 'All' ? 'Total' : selectedCategoryFilter, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            Text('€${totalSpending.toDouble()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
                children: [
                  // 1. Show the "Top 5" Quick Filters
                  ...['All', 'Groceries', 'Food Deliveries', 'Gas/Fuel', 'Utilities'].map((cat) {
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
                  }),

                  // 2. Dynamic Chip: If they select a category from the "More" grid that ISN'T in the quick list,
                  // we temporarily show it here so they know what filter is currently active!
                  if (!['All', 'Groceries', 'Food Deliveries', 'Gas/Fuel', 'Utilities'].contains(selectedCategoryFilter))
                    Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(selectedCategoryFilter),
                        selected: true,
                        selectedColor: Colors.black,
                        labelStyle: const TextStyle(color: Colors.white),
                        backgroundColor: Colors.grey[200],
                        onSelected: (bool selected) {},
                      ),
                    ),

                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      avatar: const Icon(Icons.grid_view, size: 16, color: Colors.black),
                      label: const Text('More...', style: TextStyle(color: Colors.black)),
                      backgroundColor: Colors.grey[200],
                      onPressed: _showCategoryFilterDialog,
                    ),
                  )
                ],
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
                        final bool? confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Delete Transaction?"),
                            content: const Text("Are you sure you want to permanently delete this record? This cannot be undone."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(false),
                                child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.of(ctx).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.redAccent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                ),
                                child: const Text("Delete"),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          deleteTransaction(tx.id!);
                          return true;
                        } else {
                          return false;
                        }
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
                        title: Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.category, style: TextStyle(color: tx.color, fontWeight: FontWeight.bold)),
                            Text(DateFormat('MMM d, y').format(tx.date), style: theme.textTheme.bodySmall),
                          ],
                        ),
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