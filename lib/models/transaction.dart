import 'package:flutter/material.dart';

class Transaction {
  final int? id;
  final double amount;
  final DateTime date;
  final String category;
  final IconData icon;
  final Color color;

  Transaction({
    this.id,
    required this.amount,
    required this.date,
    required this.category,
    required this.icon,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'category': category,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final style = _getCategoryStyle(map['category']);
    return Transaction(
      id: map['id'],
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
      case 'Food': return {'icon': Icons.fastfood, 'color': Colors.orange};
      case 'Transport': return {'icon': Icons.directions_bus, 'color': Colors.blue};
      case 'Shopping': return {'icon': Icons.shopping_cart, 'color': Colors.purple};
      case 'Entertainment': return {'icon': Icons.movie, 'color': Colors.redAccent};
      case 'Bills': return {'icon': Icons.receipt_long, 'color': Colors.yellow};
      case 'Health': return {'icon': Icons.local_hospital, 'color': Colors.green};
      case 'Other': return {'icon': Icons.category, 'color': Colors.grey};
      default: return {'icon': Icons.attach_money, 'color': Colors.grey};
    }
  }
}