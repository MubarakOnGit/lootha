
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Expenses
  Stream<List<Expense>> getExpensesForMonth(String monthId) {
    return _db
        .collection('expenses')
        .where('monthId', isEqualTo: monthId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Expense.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> addExpense(Expense expense) {
    return _db.collection('expenses').add(expense.toMap());
  }

  // Members
  Stream<List<Member>> getMembers() {
    return _db.collection('members').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => Member.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> addMember(Member member) {
    // Ideally use Auth ID as doc ID, but for now auto-gen or manual
    return _db.collection('members').add(member.toMap());
  }

  // Daily Meal Entries
  Stream<DailyEntry?> getDailyEntry(String dateId) {
    return _db.collection('daily_entries').doc(dateId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return DailyEntry.fromMap(doc.data()!, doc.id);
    });
  }

  Future<void> updateMealCount(
      String dateId, String memberId, int count) async {
    final docRef = _db.collection('daily_entries').doc(dateId);

    // Use set with merge to create if not exists
    await docRef.set({
      'meals': {memberId: count}
    }, SetOptions(merge: true));
  }
  
  // Get all entries for a month (need a better query or just get all for now and filter locally if dataset is small, 
  // or store monthId on daily_entry too. Assuming dateId="YYYY-MM-DD", we can't easily range query string IDs efficiently without a separate field.
  // Adding 'monthId' to DailyEntry is better.
  Stream<List<DailyEntry>> getDailyEntriesForMonth(String monthId) {
     // This requires 'monthId' field in daily_entries.
     // I will update the service to assume we add it.
     return _db.collection('daily_entries')
        .where('monthId', isEqualTo: monthId) // Need to ensure we save this
        .snapshots()
        .map((s) => s.docs.map((d) => DailyEntry.fromMap(d.data(), d.id)).toList());
  }
}
