// lib/widgets/app_sidebar.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/user_provider.dart';

/// One leaf item inside a sidebar group (e.g. "Customers").
class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.title,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String route;
}

/// A collapsible group in the sidebar (e.g. "Sales" containing
/// "Finished Sales", "Credit Sales", "Sale Categories").
class _MenuGroup {
  const _MenuGroup({
    required this.icon,
    required this.title,
    required this.items,
  });

  final IconData icon;
  final String title;
  final List<_MenuItem> items;
}

/// App-wide navigation drawer. No controllers, no badges — just routes,
/// grouped, plus a user dropdown pinned at the bottom.
class AppSidebar extends StatefulWidget {
  const AppSidebar({
    super.key,
    required this.currentRoute,
    this.creditSalesBadgeCount = 0,
  });

  final String currentRoute;

  /// Count of not-yet-finalized credit sales. Shown as a badge on the
  /// "Credit Sales" item, and as a small dot on the "Sales" group icon
  /// when the group is collapsed. Zero/omitted hides both.
  final int creditSalesBadgeCount;

  @override
  State<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends State<AppSidebar>
    with SingleTickerProviderStateMixin {
  bool _showUserMenu = false;
  late final AnimationController _animController;
  late final Animation<double> _rotationAnim;

  final Set<String> _expandedGroups = {};

  static const List<_MenuGroup> _groups = [
    _MenuGroup(
      icon: Icons.point_of_sale_outlined,
      title: 'Sales',
      items: [
        _MenuItem(
          icon: Icons.task_alt_outlined,
          title: 'Finished Sales',
          route: '/sale',
        ),
        _MenuItem(
          icon: Icons.credit_score_outlined,
          title: 'Credit Sales',
          route: '/credit-sale',
        ),
        _MenuItem(
          icon: Icons.category_outlined,
          title: 'Sale Categories',
          route: '/sale-category',
        ),
        _MenuItem(
          icon: Icons.summarize_outlined,
          title: 'Financial Statements',
          route: '/sale/financial-statement',
        ),
      ],
    ),
    _MenuGroup(
      icon: Icons.people_outline,
      title: 'Customers',
      items: [
        _MenuItem(
          icon: Icons.people_outline,
          title: 'Customers',
          route: '/customer',
        ),
      ],
    ),
    _MenuGroup(
      icon: Icons.local_shipping_outlined,
      title: 'Suppliers',
      items: [
        _MenuItem(
          icon: Icons.local_shipping_outlined,
          title: 'Suppliers',
          route: '/supplier',
        ),
      ],
    ),
    _MenuGroup(
      icon: Icons.receipt_long_outlined,
      title: 'Expenses',
      items: [
        _MenuItem(
          icon: Icons.receipt_long_outlined,
          title: 'Expenses',
          route: '/expense',
        ),
        _MenuItem(
          icon: Icons.category_outlined,
          title: 'Expense Categories',
          route: '/expense-category',
        ),
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _rotationAnim = Tween<double>(begin: 0, end: 0.5).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _expandActiveGroup());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _expandActiveGroup() {
    for (final group in _groups) {
      for (final item in group.items) {
        if (item.route == widget.currentRoute) {
          setState(() => _expandedGroups.add(group.title));
          return;
        }
      }
    }
  }

  void _navigate(String route) {
    final isActive = widget.currentRoute == route;
    Navigator.pop(context);
    if (!isActive) {
      Navigator.of(context).pushReplacementNamed(route);
    }
  }

  void _openStandaloneScreen(String route) {
    Navigator.pop(context); // close the drawer
    Navigator.of(context).pushNamed(route);
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    if (user == null) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      child: Column(
        children: [
          _buildHeader(context, colorScheme, user),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSimpleItem(
                  colorScheme: colorScheme,
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  route: '/dashboard',
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Divider(height: 1),
                ),
                ..._groups.map((group) => _buildGroup(context, colorScheme, group)),
              ],
            ),
          ),
          _buildUserSection(context, colorScheme, user),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Header
  // -------------------------------------------------------------------

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, dynamic user) {
    final initial = (user.name as String).isNotEmpty
        ? (user.name as String)[0].toUpperCase()
        : '?';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.primaryContainer],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.onPrimary,
            child: Text(
              initial,
              style: TextStyle(
                fontSize: 28,
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            (user.businessName as String?)?.isNotEmpty == true
                ? user.businessName as String
                : user.name as String,
            style: TextStyle(
              color: colorScheme.onPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // Simple item (no group)
  // -------------------------------------------------------------------

  Widget _buildSimpleItem({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String route,
  }) {
    final isActive = widget.currentRoute == route;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      child: ListTile(
        dense: true,
        leading: Icon(
          icon,
          size: 22,
          color: isActive ? colorScheme.primary : Colors.grey[700],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            color: isActive ? colorScheme.primary : Colors.black87,
          ),
        ),
        selected: isActive,
        selectedTileColor: colorScheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _navigate(route),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Collapsible group
  // -------------------------------------------------------------------

  Widget _buildGroup(BuildContext context, ColorScheme colorScheme, _MenuGroup group) {
    final isExpanded = _expandedGroups.contains(group.title);
    final hasActiveItem = group.items.any((item) => item.route == widget.currentRoute);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              if (isExpanded) {
                _expandedGroups.remove(group.title);
              } else {
                _expandedGroups.add(group.title);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: hasActiveItem
                    ? colorScheme.primary.withOpacity(0.06)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    group.icon,
                    size: 22,
                    color: hasActiveItem ? colorScheme.primary : Colors.grey[700],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      group.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: hasActiveItem ? FontWeight.w700 : FontWeight.w600,
                        color: hasActiveItem ? colorScheme.primary : Colors.black87,
                      ),
                    ),
                  ),
                  if (!isExpanded &&
                      group.title == 'Sales' &&
                      widget.creditSalesBadgeCount > 0)
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.expand_more_rounded, size: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            children: group.items
                .map((item) => _buildSubItem(
                      colorScheme,
                      item,
                      badgeCount: item.route == '/credit-sale'
                          ? widget.creditSalesBadgeCount
                          : 0,
                    ))
                .toList(),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------
  // Sub-item (indented, no badge)
  // -------------------------------------------------------------------

Widget _buildSubItem(
    ColorScheme colorScheme,
    _MenuItem item, {
    int badgeCount = 0,
  }) {
    final isActive = widget.currentRoute == item.route;
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8, top: 1, bottom: 1),
      child: ListTile(
        dense: true,
        leading: Icon(
          item.icon,
          size: 20,
          color: isActive ? colorScheme.primary : Colors.grey[600],
        ),
        title: Text(
          item.title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.normal,
            color: isActive ? colorScheme.primary : Colors.black87,
          ),
        ),
        trailing: badgeCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeCount > 99 ? '99+' : '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
        selected: isActive,
        selectedTileColor: colorScheme.primary.withOpacity(0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () => _navigate(item.route),
      ),
    );
  }

  // -------------------------------------------------------------------
  // Bottom user section — dropdown lives here
  // -------------------------------------------------------------------

  Widget _buildUserSection(BuildContext context, ColorScheme colorScheme, dynamic user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.bottomCenter,
            child: _showUserMenu
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Column(
                      children: [
                        _buildUserMenuItem(
                          icon: Icons.person_outline,
                          title: 'Edit Profile',
                          color: Colors.blue,
                          onTap: () => _openStandaloneScreen('/edit-profile'),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.lock_outline,
                          title: 'Change Password',
                          color: Colors.orange,
                          onTap: () => _openStandaloneScreen('/change-password'),
                        ),
                        Divider(height: 1, color: Colors.grey[200]),
                        _buildUserMenuItem(
                          icon: Icons.logout_outlined,
                          title: 'Log Out',
                          color: Colors.red,
                          onTap: () => _confirmLogout(context),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  _showUserMenu = !_showUserMenu;
                  _showUserMenu ? _animController.forward() : _animController.reverse();
                });
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: colorScheme.primary,
                      child: Text(
                        (user.name as String).isNotEmpty
                            ? (user.name as String)[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            [user.name, user.lastName]
                                .where((part) => part != null && (part as String).isNotEmpty)
                                .join(' '),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (user.email as String?) ?? '',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    RotationTransition(
                      turns: _rotationAnim,
                      child: Icon(Icons.expand_less_rounded, color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserMenuItem({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: title == 'Log Out' ? Colors.red : Colors.black87,
          fontSize: 13,
        ),
      ),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
    );
  }

  // -------------------------------------------------------------------
  // Logout
  // -------------------------------------------------------------------

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.logout_outlined, color: Colors.red),
            SizedBox(width: 12),
            Text('Confirm Logout'),
          ],
        ),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // TODO: replace with the real sign-out call once UserProvider
      // exposes one, e.g. `context.read<UserProvider>().logout();`
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }
}