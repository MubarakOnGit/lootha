
// Member Model
class Member {
  final String id;
  final String name;
  final String email;
  final String role; // 'admin' or 'member'
  final bool isActive;

  Member({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory Member.fromMap(Map<String, dynamic> data, String documentId) {
    return Member(
      id: documentId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'member',
      isActive: data['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}

// Expense Model
class Expense {
  final String id;
  final String title;
  final String category; // 'Mess', 'Rent', 'Electricity', 'Other'
  final double amount;
  final DateTime date;
  final String incurredBy;
  final String monthId; // Format: "YYYY-MM"

  Expense({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
    required this.incurredBy,
    required this.monthId,
  });

  factory Expense.fromMap(Map<String, dynamic> data, String documentId) {
    return Expense(
      id: documentId,
      title: data['title'] ?? '',
      category: data['category'] ?? 'Other',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      incurredBy: data['incurredBy'] ?? '',
      monthId: data['monthId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'amount': amount,
      'date': date,
      'incurredBy': incurredBy,
      'monthId': monthId,
    };
  }
}

// Daily Entry Model (for Meal Counts)
class DailyEntry {
  final String id; // Date string "YYYY-MM-DD"
  final Map<String, int> meals; // MemberID -> Count

  DailyEntry({
    required this.id,
    required this.meals,
  });

  factory DailyEntry.fromMap(Map<String, dynamic> data, String documentId) {
    return DailyEntry(
      id: documentId,
      meals: Map<String, int>.from(data['meals'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'meals': meals,
    };
  }
}

// Payment/Credit Model
class Payment {
  final String id;
  final String memberId;
  final double amount;
  final DateTime date;
  final String type; // 'Payment' (Member paid bill) or 'Advance' (Member gave money in advance)
  final String notes;

  Payment({
    required this.id,
    required this.memberId,
    required this.amount,
    required this.date,
    required this.type,
    required this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> data, String documentId) {
    return Payment(
      id: documentId,
      memberId: data['memberId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as dynamic)?.toDate() ?? DateTime.now(),
      type: data['type'] ?? 'Payment',
      notes: data['notes'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'memberId': memberId,
      'amount': amount,
      'date': date,
      'type': type,
      'notes': notes,
    };
  }
}
