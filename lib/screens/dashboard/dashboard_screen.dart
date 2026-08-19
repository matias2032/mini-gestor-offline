// screens/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '/models/sale_model.dart';
import '/providers/business_unit_provider.dart';
import '/providers/dashboard_provider.dart';
import '/providers/sale_provider.dart';
import '/providers/user_provider.dart';
import '/widgets/app_sidebar.dart';
import '/widgets/store_selector.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Dashboard Individual + Super Dashboard (FASE 5): aggregate stats for
/// either the active loja or every loja combined, over a selectable
/// period. Aggregated per store — business_category no longer exists,
/// so there is no per-category breakdown anymore.
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
      context.read<DashboardProvider>().loadStats();
      context.read<SaleProvider>().loadOutstandingCreditCount();
    });
  }

  Future<void> _refresh() async {
    await context.read<DashboardProvider>().loadStats();
    await context.read<SaleProvider>().loadOutstandingCreditCount();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = context.watch<UserProvider>().user;
    final greetingName = user?.name ?? '';
    final currency = user?.currency ?? 'MZN';

    final dashboardProvider = context.watch<DashboardProvider>();
    final saleProvider = context.watch<SaleProvider>();
    final hasMultipleUnits = context.watch<BusinessUnitProvider>().hasMultipleUnits;
    final amountFormat = NumberFormat('#,##0.00');
    final isAllStores = dashboardProvider.scope == DashboardScope.allStores;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboardTitle),
        actions: const [StoreSelector(), SizedBox(width: 8)],
      ),
      drawer: AppSidebar(
        currentRoute: '/dashboard',
        creditSalesBadgeCount: saleProvider.outstandingCreditCount,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refresh,
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
              if (hasMultipleUnits) ...[
                SegmentedButton<DashboardScope>(
                  segments: [
                    ButtonSegment(
                      value: DashboardScope.currentStore,
                      label: Text(l10n.currentStoreLabel),
                    ),
                    ButtonSegment(
                      value: DashboardScope.allStores,
                      label: Text(l10n.allStoresLabel),
                    ),
                  ],
                  selected: {dashboardProvider.scope},
                  onSelectionChanged: (selection) =>
                      context.read<DashboardProvider>().setScope(selection.first),
                ),
                const SizedBox(height: 12),
              ],
                            SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: DashboardPeriod.values.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final period = DashboardPeriod.values[index];
                    final isSelected = dashboardProvider.period == period;
                    return ChoiceChip(
                      label: Text(period.label),
                      selected: isSelected,
                      showCheckmark: true,
                      onSelected: (_) =>
                          context.read<DashboardProvider>().setPeriod(period),
                      selectedColor: Theme.of(context).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? Colors.transparent
                            : Theme.of(context).colorScheme.outlineVariant,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              if (dashboardProvider.isLoading &&
                  dashboardProvider.stats == null &&
                  dashboardProvider.consolidatedStats == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (dashboardProvider.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    dashboardProvider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                )
              else if (isAllStores)
                _ConsolidatedDashboardBody(
                  stats: dashboardProvider.consolidatedStats,
                  currency: currency,
                  amountFormat: amountFormat,
                  l10n: l10n,
                )
              else
                _CurrentStoreDashboardBody(
                  stats: dashboardProvider.stats,
                  currency: currency,
                  amountFormat: amountFormat,
                  l10n: l10n,
                ),
              if (saleProvider.outstandingCreditCount > 0) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.credit_score_outlined),
                    title: Text(l10n.creditSalesTitle),
                    subtitle: Text(
                      l10n.saleCountLabel(saleProvider.outstandingCreditCount),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushReplacementNamed('/credit-sale'),
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

class _CurrentStoreDashboardBody extends StatelessWidget {
  const _CurrentStoreDashboardBody({
    required this.stats,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final DashboardStats? stats;
  final String currency;
  final NumberFormat amountFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(l10n.dashboardNoStoreSelected),
      );
    }

    return _StatsGrid(
      cards: [
        _StatCardData(
          icon: Icons.receipt_long_outlined,
          label: l10n.finalizedSales,
          value: '${stats!.finalizedSalesCount}',
        ),
        _StatCardData(
          icon: Icons.payments_outlined,
          label: l10n.totalRevenue,
          value: '${amountFormat.format(stats!.totalRevenueCents / 100)} $currency',
        ),
        _StatCardData(
          icon: Icons.credit_score_outlined,
          label: l10n.settledCreditSales,
          value: '${stats!.settledCreditSalesCount}',
        ),
        _StatCardData(
          icon: Icons.savings_outlined,
          label: l10n.settledCreditRevenueLabel,
          value:
              '${amountFormat.format(stats!.settledCreditRevenueCents / 100)} $currency',
        ),
      ],
    );
  }
}

class _ConsolidatedDashboardBody extends StatelessWidget {
  const _ConsolidatedDashboardBody({
    required this.stats,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final ConsolidatedDashboardStats? stats;
  final String currency;
  final NumberFormat amountFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Text(l10n.dashboardNoStoreSelected),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StatsGrid(
          cards: [
            _StatCardData(
              icon: Icons.receipt_long_outlined,
              label: l10n.finalizedSales,
              value: '${stats!.finalizedSalesCount}',
            ),
            _StatCardData(
              icon: Icons.payments_outlined,
              label: l10n.totalRevenue,
              value: '${amountFormat.format(stats!.totalRevenueCents / 100)} $currency',
            ),
            _StatCardData(
              icon: Icons.credit_score_outlined,
              label: l10n.settledCreditSales,
              value: '${stats!.settledCreditSalesCount}',
            ),
            _StatCardData(
              icon: Icons.savings_outlined,
              label: l10n.settledCreditRevenueLabel,
              value:
                  '${amountFormat.format(stats!.settledCreditRevenueCents / 100)} $currency',
            ),
          ],
        ),
        if (stats!.perStore.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(l10n.perStoreBreakdownTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (final store in stats!.perStore)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.storefront_outlined),
                    title: Text(store.businessUnitName),
                    subtitle: Text(l10n.saleCountLabel(store.finalizedSalesCount)),
                    trailing: Text(
                      '${amountFormat.format(store.totalRevenueCents / 100)} $currency',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _StatCardData {
  const _StatCardData({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.cards});
  final List<_StatCardData> cards;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.3,
      children: cards
          .map((data) => _StatCard(icon: data.icon, label: data.label, value: data.value))
          .toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
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