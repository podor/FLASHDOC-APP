// lib/features/doctor/wallet/doctor_wallet_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/api_service.dart';
import '../widgets/doctor_bottom_nav.dart';

final doctorWalletProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  try {
    final res = await ApiService().getDoctorWallet();
    if (res['success'] == true) {
      return res['data'] as Map<String, dynamic>? ?? {};
    }
  } catch (_) {}
  return {};
});

class DoctorWalletScreen extends ConsumerWidget {
  const DoctorWalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(doctorWalletProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Mon wallet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700,
              color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.doctorPrimary),
            onPressed: () => ref.refresh(doctorWalletProvider.future),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.doctorPrimary,
        onRefresh: () => ref.refresh(doctorWalletProvider.future),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: walletAsync.when(
            loading: () => const Center(
                child: CircularProgressIndicator(
                    color: AppColors.doctorPrimary)),
            error: (_, __) => _WalletContent(balance: 0, transactions: const []),
            data: (data) {
              final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
              final txs = (data['transactions'] as List? ?? [])
                  .map((t) => Map<String, dynamic>.from(t))
                  .toList();
              return _WalletContent(balance: balance, transactions: txs);
            },
          ),
        ),
      ),
      bottomNavigationBar: const DoctorBottomNav(currentIndex: 2),
    );
  }
}

class _WalletContent extends StatelessWidget {
  final double balance;
  final List<Map<String, dynamic>> transactions;
  const _WalletContent({required this.balance, required this.transactions});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Carte solde
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.doctorPrimary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Solde disponible',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Text('${balance.toInt()} FCFA',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                color: Colors.white)),
          const SizedBox(height: 20),
          Row(children: [
            _WalletAction(icon: Icons.download_outlined,
                label: 'Retirer', onTap: () => _showWithdrawDialog(context)),
            const SizedBox(width: 12),
            _WalletAction(icon: Icons.history_outlined,
                label: 'Historique', onTap: () {}),
          ]),
        ]),
      ),
      const SizedBox(height: 24),

      // Transactions
      if (transactions.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 32),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 48,
                color: AppColors.textHint),
            SizedBox(height: 12),
            Text('Aucune transaction',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            SizedBox(height: 4),
            Text('Vos revenus apparaîtront ici après chaque consultation',
              style: TextStyle(fontSize: 13, color: AppColors.textHint),
              textAlign: TextAlign.center),
          ]),
        )
      else ...[
        const Align(alignment: Alignment.centerLeft,
          child: Text('Transactions récentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700,
                color: AppColors.textPrimary))),
        const SizedBox(height: 12),
        ...transactions.map((tx) => _TransactionCard(tx: tx)),
      ],
    ]);
  }

  void _showWithdrawDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Retrait Mobile Money'),
        content: const Text(
            'Sélectionnez votre opérateur pour effectuer un retrait.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Orange Money',
                style: TextStyle(color: AppColors.orangeMoney))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mtnMomo),
            child: const Text('MTN MoMo')),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> tx;
  const _TransactionCard({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = (tx['amount'] as num?)?.toDouble() ?? 0;
    final type   = tx['type'] as String? ?? '';
    final isCredit = type == 'CREDIT' || amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCredit
                ? AppColors.success.withOpacity(0.1)
                : AppColors.error.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            color: isCredit ? AppColors.success : AppColors.error,
            size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Text(type, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text(tx['description'] as String? ?? '',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(
          '${isCredit ? '+' : '-'}${amount.abs().toInt()} F',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
              color: isCredit ? AppColors.success : AppColors.error)),
      ]),
    );
  }
}

class _WalletAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _WalletAction({required this.icon, required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
