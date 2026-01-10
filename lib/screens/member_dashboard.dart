
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/dashboard_provider.dart';
import '../services/services.dart';
import '../models/app_models.dart';

class MemberDashboard extends StatelessWidget {
  const MemberDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final provider = Provider.of<DashboardProvider>(context);
    
    // Find current member
    Member? me;
    try {
      me = provider.members.firstWhere((m) => m.email == user?.email);
    } catch (e) {
      me = null;
    }

    if (me == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Access Denied')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('No member profile found for ${user?.email}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
                child: const Text('Logout'),
              )
            ],
          ),
        ),
      );
    }

    final myDue = provider.memberDues[me.id] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, ${me.name}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Provider.of<AuthService>(context, listen: false).signOut(),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatCard(context, 'Net Due Amount', '₹${myDue.toStringAsFixed(2)}', 
              myDue > 0 ? Colors.red : Colors.green),
            const SizedBox(height: 24),
            _buildRecentTransactions(context, provider, me.id),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.displaySmall?.copyWith(
            color: color, fontWeight: FontWeight.bold
          )),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions(BuildContext context, DashboardProvider provider, String myId) {
    // Filter payments for me
    final myPayments = provider.payments.where((p) => p.memberId == myId).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('My Payments & Advances', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        if (myPayments.isEmpty) 
          const Text('No payments recorded yet.', style: TextStyle(color: Colors.grey)),
        
        ...myPayments.map((p) => Card(
          child: ListTile(
            leading: Icon(p.type == 'Payment' ? Icons.payment : Icons.account_balance_wallet,
             color: Colors.blue),
            title: Text(p.type),
            subtitle: Text(p.notes),
            trailing: Text('₹${p.amount}', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        )).toList(),
      ],
    );
  }
}
