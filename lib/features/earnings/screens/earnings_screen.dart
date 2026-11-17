import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/constants.dart';
import '../../../core/utils/formatters.dart';
import '../../../widgets/empty_view.dart';
import '../../../widgets/stat_card.dart';
import '../controllers/earnings_controller.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/wallet_card.dart';
import '../widgets/withdraw_modal.dart';

class EarningsScreen extends StatefulWidget {
  final EarningsController controller;

  const EarningsScreen({super.key, required this.controller});

  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen> {
  @override
  void initState() {
    super.initState();
    // Safe initialization
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.summary == null && !widget.controller.isLoading) {
        widget.controller.fetchEarnings();
      }
    });
  }

  void _openWithdrawModal(BuildContext context) {
    final balance = widget.controller.summary?.availableBalance ?? 0;
    if (balance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No available balance to withdraw.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => WithdrawModal(controller: widget.controller),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final summary = controller.summary;

        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Earnings & Wallet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            elevation: 0,
            backgroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.info_outline_rounded),
                tooltip: 'Payout FAQ',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Payments are verified and credited within 24-48 hours.',
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: controller.fetchEarnings,
            child: _buildBody(controller, summary),
          ),
        );
      },
    );
  }

  Widget _buildBody(EarningsController controller, dynamic summary) {
    // 1. Initial Loading State
    if (controller.isLoading && summary == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.primary),
            SizedBox(height: 16),
            Text(
              'Loading ledger & balance...',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // 2. Initial Error State with Retry
    if (controller.errorMessage != null && summary == null) {
      return EmptyView(
        icon: Icons.error_outline_rounded,
        title: 'Unable to load earnings',
        message: controller.errorMessage!,
        actionLabel: 'Retry',
        onAction: controller.fetchEarnings,
      );
    }

    final transactions = controller.filteredTransactions;

    // 3. Virtualized Slivers for High-Performance Rendering (3,000+ items)
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Wallet Card
        if (summary != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: WalletCard(
                summary: summary,
                onWithdraw: () => _openWithdrawModal(context),
              ),
            ),
          ),

        // Quick Stats Row
        if (summary != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'Completed Projects',
                      value: '${summary.completedProjects}',
                      icon: Icons.task_alt_rounded,
                      iconColor: AppColors.primary,
                      iconBgColor: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'Pending Payout',
                      value: Formatters.formatCurrency(summary.pendingPayout),
                      icon: Icons.hourglass_top_rounded,
                      iconColor: AppColors.warning,
                      iconBgColor: AppColors.warningContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // Section Title: Transaction History
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  '${transactions.length} items',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Filter Chips
        SliverToBoxAdapter(
          child: SizedBox(
            height: 44,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: AppConstants.earningFilters.length,
              separatorBuilder: (_, index) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final filter = AppConstants.earningFilters[index];
                final isSelected = controller.selectedFilter == filter;
                return ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  onSelected: (_) => controller.setFilter(filter),
                );
              },
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 10)),

        // Empty state when transactions list is empty
        if (transactions.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyView(
              icon: Icons.receipt_long_outlined,
              title: 'No Transactions',
              message: 'No ledger transactions found for this filter.',
            ),
          )
        else
          // High-Performance Virtualized List using SliverList.builder
          // Effortlessly renders 3,000+ items with lazy instantiation
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 32),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                return TransactionTile(
                  key: ValueKey(transactions[index].id),
                  transaction: transactions[index],
                );
              }, childCount: transactions.length),
            ),
          ),
      ],
    );
  }
}
