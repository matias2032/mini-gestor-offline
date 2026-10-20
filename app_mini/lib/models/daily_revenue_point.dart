/* Revenue (in cents) aggregated for a single calendar day. */
class DailyRevenuePoint {
  const DailyRevenuePoint({required this.day, required this.revenueCents});

  final DateTime day;
  final int revenueCents;
}