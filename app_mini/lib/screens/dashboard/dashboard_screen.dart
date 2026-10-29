import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mini/l10n/app_localizations.dart';
import '../../models/daily_revenue_point.dart';
import '../../models/sale_model.dart';
import '../../providers/business_unit_provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../providers/sale_provider.dart';
import '../../providers/user_provider.dart';
import '../../widgets/app_sidebar.dart';
import '../../widgets/store_selector.dart';

/* Individual & Consolidated Dashboard: Displays aggregated statistics 
   for either the active store or across all business units for a selected period. */
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
                  dailyRevenue: dashboardProvider.dailyRevenue,
                  currency: currency,
                  amountFormat: amountFormat,
                  l10n: l10n,
                )
              else
                _CurrentStoreDashboardBody(
                  stats: dashboardProvider.stats,
                  dailyRevenue: dashboardProvider.dailyRevenue,
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
    required this.dailyRevenue,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final DashboardStats? stats;
  final List<DailyRevenuePoint> dailyRevenue;
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
        const SizedBox(height: 12),
        _RevenueTrendCard(
          points: dailyRevenue,
          currency: currency,
          amountFormat: amountFormat,
          l10n: l10n,
        ),
        const SizedBox(height: 12),
        _RevenueMixCard(
          totalCents: stats!.totalRevenueCents,
          creditCents: stats!.settledCreditRevenueCents,
          currency: currency,
          amountFormat: amountFormat,
          l10n: l10n,
        ),
      ],
    );
  }
}

class _ConsolidatedDashboardBody extends StatelessWidget {
  const _ConsolidatedDashboardBody({
    required this.stats,
    required this.dailyRevenue,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final ConsolidatedDashboardStats? stats;
  final List<DailyRevenuePoint> dailyRevenue;
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
        const SizedBox(height: 12),
        _RevenueTrendCard(
          points: dailyRevenue,
          currency: currency,
          amountFormat: amountFormat,
          l10n: l10n,
        ),
        const SizedBox(height: 12),
        _RevenueMixCard(
          totalCents: stats!.totalRevenueCents,
          creditCents: stats!.settledCreditRevenueCents,
          currency: currency,
          amountFormat: amountFormat,
          l10n: l10n,
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
                  Column(
                    children: [
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
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: LinearProgressIndicator(
                          value: stats!.totalRevenueCents > 0
                              ? store.totalRevenueCents / stats!.totalRevenueCents
                              : 0,
                          minHeight: 4,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
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

class _RevenueMixCard extends StatelessWidget {
  const _RevenueMixCard({
    required this.totalCents,
    required this.creditCents,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final int totalCents;
  final int creditCents;
  final String currency;
  final NumberFormat amountFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    if (totalCents <= 0) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final credit = creditCents.clamp(0, totalCents).toInt();
    final immediate = totalCents - credit;
    final fraction = credit / totalCents;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              height: 76,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(76, 76),
                    painter: _DonutPainter(
                      fraction: fraction,
                      baseColor: colorScheme.primary,
                      highlightColor: colorScheme.tertiary,
                    ),
                  ),
                  Text(
                    '${(fraction * 100).round()}%',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.revenueMixTitle, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 8),
                  _LegendRow(
                    color: colorScheme.primary,
                    label: l10n.immediateRevenueLabel,
                    value: '${amountFormat.format(immediate / 100)} $currency',
                  ),
                  const SizedBox(height: 4),
                  _LegendRow(
                    color: colorScheme.tertiary,
                    label: l10n.settledCreditRevenueLabel,
                    value: '${amountFormat.format(credit / 100)} $currency',
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

class _LegendRow extends StatelessWidget {
  const _LegendRow({required this.color, required this.label, required this.value});
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.fraction,
    required this.baseColor,
    required this.highlightColor,
  });

  final double fraction;
  final Color baseColor;
  final Color highlightColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 10.0;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawArc(rect, 0, 2 * math.pi, false, paint..color = baseColor);
    if (fraction > 0) {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * fraction,
        false,
        paint..color = highlightColor,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.fraction != fraction ||
      old.baseColor != baseColor ||
      old.highlightColor != highlightColor;
}

class _RevenueTrendCard extends StatelessWidget {
  const _RevenueTrendCard({
    required this.points,
    required this.currency,
    required this.amountFormat,
    required this.l10n,
  });

  final List<DailyRevenuePoint> points;
  final String currency;
  final NumberFormat amountFormat;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final hasData = points.length >= 3 && points.any((p) => p.revenueCents > 0);
    if (!hasData) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat('d MMM', locale);
    final peak = points.map((p) => p.revenueCents).reduce(math.max);
    final labelStyle = TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.revenueTrendTitle,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  '${l10n.peakLabel}: ${amountFormat.format(peak / 100)} $currency',
                  style: labelStyle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 90,
              width: double.infinity,
              child: CustomPaint(
                painter: _LineChartPainter(
                  values: points.map((p) => p.revenueCents.toDouble()).toList(),
                  lineColor: colorScheme.primary,
                  gridColor: colorScheme.outlineVariant,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateFormat.format(points.first.day), style: labelStyle),
                Text(dateFormat.format(points.last.day), style: labelStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<double> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    const pad = 4.0;
    final maxValue = values.reduce(math.max);
    final top = maxValue <= 0 ? 1.0 : maxValue;
    final dx = size.width / (values.length - 1);
    final usableHeight = size.height - pad * 2;

    final offsets = [
      for (var i = 0; i < values.length; i++)
        Offset(i * dx, size.height - pad - (values[i] / top) * usableHeight),
    ];

    // Baseline
    canvas.drawLine(
      Offset(0, size.height - 0.5),
      Offset(size.width, size.height - 0.5),
      Paint()
        ..color = gridColor
        ..strokeWidth = 1,
    );

    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final o in offsets.skip(1)) {
      line.lineTo(o.dx, o.dy);
    }

    // Soft fill under the line
    final fill = Path.from(line)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withValues(alpha: 0.25), lineColor.withValues(alpha: 0.0)],
        ).createShader(Offset.zero & size),
    );

    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    // Dot on the most recent day
    canvas.drawCircle(offsets.last, 3.5, Paint()..color = lineColor);
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      !listEquals(old.values, values) ||
      old.lineColor != lineColor ||
      old.gridColor != gridColor;
}