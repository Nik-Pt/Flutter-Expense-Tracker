import 'package:flutter/material.dart';

class Transaction {
  final int? id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  final Color color;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final style = _getCategoryStyle(map['category']);
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount'],
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      category: map['category'],
      icon: style['icon'],
      color: style['color'],
    );
  }

  static Map<String, dynamic> getCategoryStyle(String category) {
    return _getCategoryStyle(category);
  }

  static Map<String, dynamic> _getCategoryStyle(String category) {
    switch (category) {
      case 'Groceries': return {'icon': Icons.shopping_basket, 'color': Colors.green};
      case 'Food Deliveries': return {'icon': Icons.restaurant, 'color': Colors.deepOrange};
      case 'Coffee': return {'icon': Icons.coffee, 'color': Colors.brown};
      case 'Alcohol/Bars': return {'icon': Icons.wine_bar, 'color': Colors.purpleAccent};
      case 'Gas/Fuel': return {'icon': Icons.local_gas_station, 'color': Colors.blueGrey};
      case 'Public Transit': return {'icon': Icons.directions_transit, 'color': Colors.blue};
      case 'Taxi/Uber': return {'icon': Icons.local_taxi, 'color': Colors.amber};
      case 'Car Maintenance': return {'icon': Icons.build, 'color': Colors.grey.shade700};
      case 'Rent/Mortgage': return {'icon': Icons.house, 'color': Colors.teal};
      case 'Utilities': return {'icon': Icons.bolt, 'color': Colors.yellow.shade700};
      case 'Internet/Phone': return {'icon': Icons.wifi, 'color': Colors.cyan};
      case 'Outings': return {'icon': Icons.local_activity, 'color': Colors.pinkAccent};
      case 'Subscriptions': return {'icon': Icons.subscriptions, 'color': Colors.red};
      case 'Gaming': return {'icon': Icons.sports_esports, 'color': Colors.deepPurple};
      case 'Gambling': return {'icon': Icons.casino, 'color': Colors.deepPurpleAccent};
      case 'Crypto/Shares': return {'icon': Icons.currency_bitcoin, 'color': Colors.yellowAccent};
      case 'Clothing': return {'icon': Icons.checkroom, 'color': Colors.pink};
      case 'Electronics': return {'icon': Icons.devices, 'color': Colors.blueGrey.shade700};
      case 'Gifts': return {'icon': Icons.card_giftcard, 'color': Colors.redAccent};
      case 'Fitness/Gym': return {'icon': Icons.fitness_center, 'color': Colors.orangeAccent};
      case 'Pharmacy': return {'icon': Icons.medical_services, 'color': Colors.lightGreenAccent};
      case 'Personal Care': return {'icon': Icons.spa, 'color': Colors.pink.shade300};
      case 'Trips/Travel': return {'icon': Icons.flight_takeoff, 'color': Colors.lightBlue};
      case 'Education': return {'icon': Icons.school, 'color': Colors.blue.shade800};
      case 'Pets': return {'icon': Icons.pets, 'color': Colors.brown.shade300};
      case 'Other': return {'icon': Icons.category, 'color': Colors.grey};
      default: return {'icon': Icons.attach_money, 'color': Colors.grey};
    }
  }
}