# Flutter Expense Tracker

This is my first project in flutter and it is
a modern, and clean, expense tracking application built with Flutter. This app helps users track their daily spending, categorize expenses, and visualize their financial habits with interactive charts.

## Features

* **Transaction Management:** Add, Edit, and Delete expenses easily.
    * *Swipe Left* to Delete.
    * *Swipe Right* to Edit.
* **Visual Analytics:** A dynamic Pie Chart that updates based on your spending.
* **Filtering:**
    * Navigate through months.
    * Filter by specific categories (e.g., see only "Food" expenses).
* **Persistent Storage:** Data is saved locally on the device using SQLite, so it's never lost.
* **Dark Mode:** Fully supported Dark/Light theme toggle (Quite unessesary but whatever).

## Tech Stack & Packages

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Database:** [sqflite](https://pub.dev/packages/sqflite) (Local SQL Database)
* **Charts:** [fl_chart](https://pub.dev/packages/fl_chart)
* **Formatting:** [intl](https://pub.dev/packages/intl)

## Project Structure

The project has been refactored for scalability and readability:

```text
lib/
├── models/         # Data blueprints (Transaction class)
├── providers/      # State management (Theme logic)
├── screens/        # Full-page UI views (Dashboard)
├── services/       # Backend logic (Database operations)
├── widgets/        # Reusable UI components (Input forms)
└── main.dart       # App entry point
```

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
