// lib/screens/order_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'order_details_screen.dart';
import 'create_order_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});
  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  List<dynamic> _orders = [];
  String? _businessId;

  // Search & Filter
  final TextEditingController _searchController = TextEditingController();
  String? _statusFilter;

  // Animations
  AnimationController? _pageAnim; // drives page fade-in
  static const _staggerMs = 70; // item delay per index

  @override
  void initState() {
    super.initState();
    _pageAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pageAnim?.dispose();
    _pageAnim = null;
    super.dispose();
  }

  Future<void> _fetchData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token!;
      final businesses = await _apiService.getMyBusinesses(token);

      if (businesses.isEmpty) {
        if (!mounted) return;
        setState(() {
          _orders = [];
          _businessId = null;
          _isLoading = false;
        });
        return;
      }

      final businessId = businesses[0]['id'];
      final orders = await _apiService.getOrdersByBusiness(
        businessId,
        token,
        search: _searchController.text.trim(),
        status: _statusFilter,
      );

      if (!mounted) return;
      setState(() {
        _orders = orders;
        _businessId = businessId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load orders: $e'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _navigateToCreateOrder() async {
    if (_businessId == null) return;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => CreateOrderScreen(businessId: _businessId!),
      ),
    );
    if (result == true) _fetchData();
  }

  String _formatDate(String dateString) =>
      DateFormat('MMM dd, yyyy').format(DateTime.parse(dateString));

  // Status → color/gradient helpers
  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return const Color(0xFFFFB020);
      case 'processing':
        return const Color(0xFF3B82F6);
      case 'shipped':
        return const Color(0xFF8B5CF6);
      case 'delivered':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF64748B);
    }
  }

  List<Color> _statusGradient(String? status) {
    final base = _statusColor(status);
    return [base.withOpacity(0.95), base.withOpacity(0.80)];
  }

  IconData _statusIcon(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'pending':
        return Icons.hourglass_bottom_rounded;
      case 'processing':
        return Icons.settings_rounded;
      case 'shipped':
        return Icons.local_shipping_rounded;
      case 'delivered':
        return Icons.verified_rounded;
      case 'cancelled':
        return Icons.cancel_rounded;
      default:
        return Icons.receipt_long_rounded;
    }
  }

  void _openFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final options = _filterOptions;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Filter by Status',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                'Quickly narrow down your orders.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              ...options.map((opt) {
                final selected =
                    _statusFilter == opt ||
                    (_statusFilter == null && opt == 'All');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: _statusColor(opt).withOpacity(0.12),
                    child: Icon(_statusIcon(opt), color: _statusColor(opt)),
                  ),
                  title: Text(opt),
                  trailing: selected
                      ? const Icon(
                          Icons.check_rounded,
                          color: Color(0xFF3B82F6),
                        )
                      : null,
                  onTap: () {
                    setState(() {
                      _statusFilter = opt == 'All' ? null : opt;
                    });
                    Navigator.pop(ctx);
                    _fetchData();
                  },
                );
              }).toList(),
              const SizedBox(height: 4),
            ],
          ),
        );
      },
    );
  }

  Future<void> _onPullToRefresh() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    final pageOpacity = _pageAnim != null
        ? CurvedAnimation(parent: _pageAnim!, curve: Curves.easeOutCubic)
        : const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: _ColorfulAppBar(title: 'Orders', onRefresh: _fetchData),
      body: FadeTransition(
        opacity: pageOpacity,
        child: RefreshIndicator(
          onRefresh: _onPullToRefresh,
          color: const Color(0xFF7C3AED),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      // Search pill
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                                color: Colors.black.withOpacity(0.05),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) => _fetchData(),
                            decoration: InputDecoration(
                              hintText: 'Search by customer, ID, status…',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        _fetchData();
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Filter button
                      _FilledIconButton(
                        icon: Icons.tune_rounded,
                        onTap: _openFilterSheet,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF22D3EE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Filter quick chips (colorful)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 44,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _filterOptions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) {
                      final label = _filterOptions[i];
                      final selected =
                          _statusFilter == label ||
                          (_statusFilter == null && label == 'All');
                      return _ColorfulChip(
                        label: label,
                        icon: _statusIcon(label),
                        selected: selected,
                        color: _statusColor(label),
                        onTap: () {
                          setState(() {
                            _statusFilter = (label == 'All') ? null : label;
                          });
                          _fetchData();
                        },
                      );
                    },
                  ),
                ),
              ),

              // List content
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF7C3AED),
                      ),
                    ),
                  ),
                )
              else if (_orders.isEmpty)
                SliverFillRemaining(child: _EmptyState(onRefresh: _fetchData))
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  sliver: SliverList.separated(
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final order = _orders[index];

                      // per-item staggered animation (fade + slide + scale)
                      final itemDuration = Duration(milliseconds: 420);
                      final itemDelay = Duration(
                        milliseconds: index * _staggerMs,
                      );

                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: itemDuration,
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          final dx = (1 - value) * 24; // slide up
                          final scale = 0.98 + (value * 0.02);
                          return Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, dx),
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: _OrderCard(
                          order: order,
                          dateText: _formatDate(order['order_date'].toString()),
                          amountText: _formatAmount(order['total_amount']),
                          statusText: (order['status'] ?? '').toString(),
                          statusIcon: _statusIcon(order['status']),
                          gradientColors: _statusGradient(order['status']),
                          onTap: () async {
                            final result = await Navigator.of(context)
                                .push<bool>(
                                  MaterialPageRoute(
                                    builder: (context) => OrderDetailsScreen(
                                      orderId: order['id'],
                                    ),
                                  ),
                                );
                            if (result == true) _fetchData();
                          },
                        ),
                      );
                    },
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: _NewOrderFAB(onPressed: _navigateToCreateOrder),
    );
  }

  static const List<String> _filterOptions = [
    'All',
    'Pending',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  String _formatAmount(dynamic amount) {
    final numVal = num.tryParse(amount?.toString() ?? '') ?? 0; // safe parse
    return 'LKR ${NumberFormat('#,##0.00').format(numVal)}';
  }
}

/// Colorful rounded AppBar with gradient & refresh
class _ColorfulAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onRefresh;

  const _ColorfulAppBar({required this.title, required this.onRefresh});

  @override
  Size get preferredSize => const Size.fromHeight(86);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      elevation: 0,
      centerTitle: true,
      titleSpacing: 0,
      toolbarHeight: 86,
      backgroundColor: Colors.transparent,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF2563EB), Color(0xFF06B6D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(top: 10.0),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: onRefresh,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 6),
      ],
    );
  }
}

/// Small filled gradient icon button (for filter)
class _FilledIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Gradient gradient;

  const _FilledIconButton({
    required this.icon,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.tune_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

/// Colorful selectable chip with icon
class _ColorfulChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ColorfulChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? color.withOpacity(0.18) : Colors.white;
    final border = selected ? color.withOpacity(0.45) : Colors.grey.shade300;
    final textColor = selected ? color.darken(0.1) : Colors.grey.shade700;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: border, width: 1),
          ),
          child: Row(
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single colorful order card
class _OrderCard extends StatelessWidget {
  final dynamic order;
  final String dateText;
  final String amountText;
  final String statusText;
  final IconData statusIcon;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _OrderCard({
    required this.order,
    required this.dateText,
    required this.amountText,
    required this.statusText,
    required this.statusIcon,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final customerName = (order['customer_name'] ?? '').toString().trim();
    final title = customerName.isEmpty ? 'Unknown Customer' : customerName;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [gradientColors.first, gradientColors.last],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.last.withOpacity(0.30),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon badge
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.20),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.25)),
                  ),
                  child: Icon(statusIcon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                // Middle info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer name
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Flexible(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    dateText,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.payments_rounded,
                                  size: 16,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    amountText,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.95),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Status chip & arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.25),
                        ),
                      ),
                      child: Text(
                        statusText.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Empty state
class _EmptyState extends StatelessWidget {
  final VoidCallback onRefresh;
  const _EmptyState({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Decorative empty icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF60A5FA), Color(0xFFA78BFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF60A5FA).withOpacity(0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No orders yet',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first order to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRefresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extended FAB with nice shape/blur-like effect
class _NewOrderFAB extends StatelessWidget {
  final VoidCallback onPressed;
  const _NewOrderFAB({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.transparent,
      elevation: 10,
      shadowColor: Colors.black.withOpacity(0.25),
      borderRadius: BorderRadius.circular(18),
      child: FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New Order',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

// ------------ Small color extension for chip tone ------------
extension on Color {
  Color darken([double amount = .1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}
