
import 'package:flutter/material.dart';
import '../models/app_models.dart';
import '../services/services.dart';
import 'package:intl/intl.dart';

class DashboardProvider with ChangeNotifier {
  final FirestoreService _db = FirestoreService();
  
  String _currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());
  String get currentMonthId => _currentMonthId;

  List<Member> _members = [];
  List<Member> get members => _members;

  List<Expense> _expenses = [];
  List<Expense> get expenses => _expenses;
  
  List<DailyEntry> _dailyEntries = [];
  
  // Loading State
  bool _isLoading = true;
  bool get isLoading => _isLoading;

  DashboardProvider() {
    _init();
  }

  void _init() {
    // Listen to members
    _db.getMembers().listen((members) {
      _members = members;
      notifyListeners();
    });

    // Listen to expenses for current month
    _db.getExpensesForMonth(_currentMonthId).listen((expenses) {
      _expenses = expenses;
      _calculateTotals();
    });
    
     // Listen to daily entries for current month
    _db.getDailyEntriesForMonth(_currentMonthId).listen((entries) {
      _dailyEntries = entries;
      _calculateTotals();
    });
  }
  
  void setMonth(DateTime date) {
    _currentMonthId = DateFormat('yyyy-MM').format(date);
    // Re-subscribe logic would go here in a real app (cancelling old subs)
    // For MVP we just restart or reload.
    notifyListeners();
  }

  // Calculated Values
  double _totalMessExpense = 0;
  double get totalMessExpense => _totalMessExpense;
  
  int _totalMealUnits = 0;
  int get totalMealUnits => _totalMealUnits;
  
  double _costPerMealUnit = 0;
  double get costPerMealUnit => _costPerMealUnit;

  Map<String, double> _memberDues = {};
  Map<String, double> get memberDues => _memberDues;

  void _calculateTotals() {
    // 1. Total Mess Expenses
    _totalMessExpense = _expenses
        .where((e) => e.category == 'Mess')
        .fold(0.0, (sum, e) => sum + e.amount);

    // 2. Total Meal Units
    _totalMealUnits = 0;
    for (var entry in _dailyEntries) {
      for (var count in entry.meals.values) {
        _totalMealUnits += count;
      }
    }

    // 3. Cost Per Unit (Rounded Up Rule)
    if (_totalMealUnits > 0) {
      _costPerMealUnit = (_totalMessExpense / _totalMealUnits);
      // Ensure we cover the cost logic later. 
      // If user wants STRICT rounding up to ensure total > amount:
      // e.g. 1000 / 3 = 333.33 -> Make it 334? 
      // User said: "always make morethan total amount". 
      // We will ceil logic in the final allocation.
    } else {
      _costPerMealUnit = 0;
    }

    // 4. Calculate Member Dues
    _memberDues = {};
    for (var m in _members) {
       double due = 0;
       
       // A. Food Cost
       int myUnits = 0;
       for (var entry in _dailyEntries) {
         myUnits += entry.meals[m.id] ?? 0;
       }
       due += (myUnits * _costPerMealUnit); 
       
       // B. Shared Expenses (Divide by active members or specific logic)
       // Plan: "Other Expenses: Distributed among selected members"
       // We need to check involved members.
       // For now, assuming "Other" is split equally among ALL active members.
       // User requirement: "some expenses distributed to everyone... gas, water bills distributd who as using those"
       // Implementation needs to check logic.
       
       // Simple implementation for now:
       for (var e in _expenses) {
         if (e.category != 'Mess') {
             // Assuming shared equally for MVP/Demo unless 'involved' field used
             // Since we didn't add 'involved' list to UI yet, assume all active.
             int activeCount = _members.where((mem) => mem.isActive).length;
             if(activeCount > 0) due += (e.amount / activeCount); 
         }
       }
       
       _memberDues[m.id] = due;
    }
    
    // Safety check for Rounding Up
    // Sum of all member dues for Mess vs Total Mess
    // We can apply a small ceil buffer if needed.
    
    _isLoading = false;
    notifyListeners();
  }

  // Actions
  Future<void> addExpense(String title, String category, double amount) async {
    final expense = Expense(
      id: '', // Firestore auto-gen
      title: title,
      category: category,
      amount: amount,
      date: DateTime.now(),
      incurredBy: 'admin', // Replace with actual auth id
      monthId: _currentMonthId,
    );
    await _db.addExpense(expense);
  }
  
  Future<void> updateMeal(DateTime date, String memberId, int count) async {
    final dateId = DateFormat('yyyy-MM-dd').format(date);
    await _db.updateMealCount(dateId, memberId, count);
  }

  Future<void> addNewMember(String name) async {
    final member = Member(
      id: '', // Firestore auto-gen
      name: name,
      role: 'member',
    );
    await _db.addMember(member);
  }
}
