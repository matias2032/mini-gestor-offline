// screens/dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '/models/sale_model.dart';
import '/providers/sale_provider.dart';
import '/providers/user_provider.dart';
import '/widgets/app_sidebar.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Dashboard's role changed from "grid of module shortcuts" to "sales
/// stats screen" now that AppSidebar owns all navigation. It shows:
///  - count of finalized sales (NORMAL always finalized; CREDIT only once
///    COMPLETED — a cancelled/still-open credit sale contributes nothing)
///  - total value of all finalized sales
///  - total value of finalized credit sales specifically
///  - a per-category breakdown
/// All of it scoped to a period filter (today / 1 day / 1 week / 1 month /
/// 3 months / 6 months / 1 year).
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saleProvider = context.read<SaleProvider>();
      saleProvider.loadDashboardStats();
      saleProvider.loadOutstandingCreditCount();
    });
  }

  void _onPeriodChanged(DashboardPeriod period) {
    context.read<SaleProvider>().loadDashboardStats(period: period);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<UserProvider>().user;
    final greetingName = user?.name ?? '';
    final currency = user?.currency ?? 'MZN';

    final saleProvider = context.watch<SaleProvider>();
    final stats = saleProvider.dashboardStats;
    final selectedPeriod = saleProvider.dashboardPeriod;
    final isLoading = saleProvider.isLoading;

    final amountFormat = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(title: Text(l10n.dashboardTitle)),
      drawer: AppSidebar(
        currentRoute: '/dashboard',
        creditSalesBadgeCount: saleProvider.outstandingCreditCount,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context
              .read<SaleProvider>()
              .loadDashboardStats(period: selectedPeriod),
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text(
                greetingName.isNotEmpty
                    ? l10n.helloUser(greetingName)
                    : l10n.hello,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.salesDoingIntro,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),

              _PeriodFilter(
                selected: selectedPeriod,
                onChanged: _onPeriodChanged,
              ),
              const SizedBox(height: 20),

              if (isLoading && stats.finalizedSalesCount == 0 &&
                  stats.categorySummaries.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.task_alt_outlined,
                        label: l10n.finalizedSales,
                        value: '${stats.finalizedSalesCount}',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.payments_outlined,
                        label: l10n.totalRevenue,
                        value:
                            '${amountFormat.format(stats.totalAllSalesCents / 100)} $currency',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.credit_score_outlined,
                  label: l10n.settledCreditSales,
                  value:
                      '${amountFormat.format(stats.totalCreditSalesCents / 100)} $currency',
                  wide: true,
                ),

                const SizedBox(height: 28),
                Text(
                  l10n.salesByCategory,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (stats.categorySummaries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(l10n.noCategoriesYet),
                  )
                else
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (final category in stats.categorySummaries)
                          _CategoryRow(
                            category: category,
                            currency: currency,
                            amountFormat: amountFormat,
                            maxCents: stats.categorySummaries
                                .map((c) => c.totalCents)
                                .fold<int>(0, (a, b) => a > b ? a : b),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PeriodFilter extends StatelessWidget {
  const _PeriodFilter({required this.selected, required this.onChanged});

  final DashboardPeriod selected;
  final ValueChanged<DashboardPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: DashboardPeriod.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final period = DashboardPeriod.values[index];
          final isSelected = period == selected;
          return ChoiceChip(
            label: Text(period.label),
            selected: isSelected,
            onSelected: (_) => onChanged(period),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    this.wide = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.currency,
    required this.amountFormat,
    required this.maxCents,
  });

  final CategorySalesSummary category;
  final String currency;
  final NumberFormat amountFormat;
  final int maxCents;

  @override
  Widget build(BuildContext context) {
    final ratio = maxCents > 0 ? category.totalCents / maxCents : 0.0;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  category.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${amountFormat.format(category.totalCents / 100)} $currency',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.saleCountLabel(category.saleCount),
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}