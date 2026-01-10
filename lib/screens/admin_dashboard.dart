
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/services.dart';
import '../providers/dashboard_provider.dart';
import '../models/app_models.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Admin'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: 'Summary'),
            Tab(text: 'Log Meals'),
            Tab(text: 'Expenses'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Member',
            onPressed: () => _showAddMemberDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
               // Invoke logout from AuthService via context or import
               Provider.of<AuthService>(context, listen: false).signOut();
            },
          )
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          SummaryTab(),
          MealLoggingTab(),
          ExpensesTab(),
        ],
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Member'),
        content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
             TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email (for Login)')),
           ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty && emailController.text.isNotEmpty) {
                 Provider.of<DashboardProvider>(context, listen: false)
                     .addNewMember(nameController.text, emailController.text);
                 Navigator.pop(context);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}

class SummaryTab extends StatelessWidget {
  const SummaryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());

    return RefreshIndicator(
      onRefresh: () async {
        // Trigger reload if needed
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCard(
            'Total Mess Expense',
            '₹${provider.totalMessExpense.toStringAsFixed(2)}',
            Icons.restaurant,
            Colors.orange,
          ),
          _buildCard(
            'Total Meal Units',
            '${provider.totalMealUnits}',
            Icons.calculate,
            Colors.green,
          ),
          _buildCard(
            'Cost Per Unit',
            '₹${provider.costPerMealUnit.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.blue,
          ),
          const SizedBox(height: 24),
          Text('Member Dues', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          ...provider.members.map((m) {
            final due = provider.memberDues[m.id] ?? 0;
            return Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(m.name[0])),
                title: Text(m.name),
                subtitle: Text(m.email.isNotEmpty ? m.email : 'No Email'), // Show Email
                trailing: Row(
                   mainAxisSize: MainAxisSize.min,
                   children: [
                      Text(
                        '₹${due.ceil()}', 
                        style: TextStyle(
                           fontWeight: FontWeight.bold, 
                           fontSize: 16,
                           color: due > 0 ? Colors.red : Colors.green
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Add Payment Button
                      IconButton(
                        icon: const Icon(Icons.payments, color: Colors.blue),
                        onPressed: () => _showPaymentDialog(context, m),
                      ),
                   ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  void _showPaymentDialog(BuildContext context, Member member) {
     final amountCtrl = TextEditingController();
     final notesCtrl = TextEditingController();
     String type = 'Payment'; // or Advance
     
     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
         title: Text('Add Transaction for ${member.name}'),
         content: Column(
           mainAxisSize: MainAxisSize.min,
           children: [
             DropdownButtonFormField<String>(
               initialValue: type,
               items: ['Payment', 'Advance'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
               onChanged: (v) => type = v!,
               decoration: const InputDecoration(labelText: 'Type'),
             ),
             const SizedBox(height: 8),
             TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
             const SizedBox(height: 8),
             TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes')),
           ],
         ),
         actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                 if (amountCtrl.text.isNotEmpty) {
                    Provider.of<DashboardProvider>(context, listen: false)
                        .addPayment(member.id, double.tryParse(amountCtrl.text) ?? 0, type, notesCtrl.text);
                    Navigator.pop(ctx);
                 }
              },
              child: const Text('Save'),
            )
         ],
       ),
     );
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.grey)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MealLoggingTab extends StatefulWidget {
  const MealLoggingTab({super.key});

  @override
  State<MealLoggingTab> createState() => _MealLoggingTabState();
}

class _MealLoggingTabState extends State<MealLoggingTab> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    // Find entry for selected date locally from provider or fetch (provider has monthly list)
    // For MVP, provider might need a helper, or we just look it up.
    // Provider._dailyEntries is private list. We can expose a getter or helper.
    // Assuming we fetch specific daily entry logic or simplify:
    
    return Column(
      children: [
        CalendarDatePicker(
          initialDate: _selectedDate,
          firstDate: DateTime(2023),
          lastDate: DateTime.now(),
          onDateChanged: (d) => setState(() => _selectedDate = d),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: provider.members.length,
            itemBuilder: (context, index) {
              final member = provider.members[index];
              // Hacky: finding count. Ideally provider gives a map for the date.
              int currentCount = 0; 
              // We need to implement this lookup in UI or Provider.
              // Letting user toggle: 0 -> 1 -> 2 -> 3 -> 0
              
              return ListTile(
                title: Text(member.name),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                         // provider.updateMeal(_selectedDate, member.id, currentCount - 1);
                      },
                    ),
                    Text('$currentCount', style: const TextStyle(fontSize: 18)),
                    IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          // provider.updateMeal(_selectedDate, member.id, currentCount + 1);
                        }
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class ExpensesTab extends StatelessWidget {
  const ExpensesTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<DashboardProvider>(context);

    // Simple List + FAB
    return Scaffold(
      body: ListView.builder(
        itemCount: provider.expenses.length,
        itemBuilder: (context, index) {
          final e = provider.expenses[index];
          return ListTile(
            leading: Icon(e.category == 'Mess' ? Icons.restaurant : Icons.receipt),
            title: Text(e.title),
            subtitle: Text(DateFormat('MMM dd').format(e.date)),
            trailing: Text('₹${e.amount}'),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddExpenseDialog(context, provider);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddExpenseDialog(BuildContext context, DashboardProvider provider) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'Mess';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16, top: 16, left: 16, right: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add Expense', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title (e.g. Eggs)')),
            const SizedBox(height: 8),
            TextField(controller: amountCtrl, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              items: ['Mess', 'Rent', 'Electricity', 'Other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => category = v!,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.isNotEmpty && amountCtrl.text.isNotEmpty) {
                  provider.addExpense(titleCtrl.text, category, double.tryParse(amountCtrl.text) ?? 0);
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Add'),
            )
          ],
        ),
      ),
    );
  }
}
