import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../config/api_config.dart';
import '../models/vehicle.dart';
import '../providers/vehicle_providers.dart';
import '../repositories/vehicle_repository.dart';
import '../services/auth_service.dart';
import '../widgets/vehicle_delete_dialog.dart';
import '../widgets/vehicle_row_card.dart';
import 'login_screen.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends ConsumerStatefulWidget {
  const VehicleListScreen({super.key});

  @override
  ConsumerState<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends ConsumerState<VehicleListScreen> {
  // Own simple pagination (no dependency on infinite_scroll_pagination,
  // so it works with any package version).
  final List<Vehicle> _items = [];
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  int _nextPage = 0;
  bool _hasNext = true;
  bool _isLoading = false;
  bool _initialLoadDone = false;
  Object? _error;
  int _generation = 0; // ignore responses of old (refreshed-away) requests

  String _searchQuery = '';
  VehicleStatus? _statusFilter;
  int _filterResetCount = 0; // bumps on Clear so the dropdown resets to All

  bool get _isFiltering => _searchQuery.isNotEmpty || _statusFilter != null;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNextPage());
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300 && _error == null) {
      _loadNextPage();
    }
  }

  Future<void> _loadNextPage() async {
    if (_isLoading || !_hasNext) return;
    final gen = _generation;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(vehicleRepositoryProvider).getVehicles(
            page: _nextPage,
            size: ApiConfig.defaultPageSize,
          );
      if (!mounted || gen != _generation) return;
      ref
          .read(totalVehiclesCountProvider.notifier)
          .setCount(response.totalElements);
      setState(() {
        _items.addAll(response.content);
        _nextPage++;
        _hasNext = response.hasNext;
        _isLoading = false;
        _initialLoadDone = true;
      });
    } catch (e) {
      if (!mounted || gen != _generation) return;
      setState(() {
        _error = e;
        _isLoading = false;
      });
      return;
    }
    _maybeLoadMore();
  }


  void _maybeLoadMore() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_hasNext || _isLoading || _error != null) return;
      final notScrollable =
          _scrollCtrl.hasClients && _scrollCtrl.position.maxScrollExtent <= 0;
      if (_isFiltering || notScrollable) _loadNextPage();
    });
  }

  void _refresh() {
    _generation++;
    setState(() {
      _items.clear();
      _nextPage = 0;
      _hasNext = true;
      _isLoading = false;
      _initialLoadDone = false;
      _error = null;
    });
    _loadNextPage();
  }

  bool _matchesFilter(Vehicle v) {
    if (_statusFilter != null && v.status != _statusFilter) return false;
    if (_searchQuery.isEmpty) return true;
    final q = _searchQuery.toLowerCase();
    return v.vehicleNumber.toLowerCase().contains(q) ||
        v.brand.toLowerCase().contains(q) ||
        v.model.toLowerCase().contains(q) ||
        (v.driverName?.toLowerCase().contains(q) ?? false);
  }

  Future<void> _openForm({Vehicle? vehicle}) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VehicleFormScreen(vehicle: vehicle),
      ),
    );
    if (changed == true) _refresh();
  }

  Future<void> _confirmDelete(Vehicle vehicle) async {
    final id = vehicle.id;
    if (id == null) return;
    final confirmed = await showVehicleDeleteDialog(context, vehicle);
    if (confirmed != true || !mounted) return;

    final toaster = ShadToaster.of(context);
    try {
      await ref.read(vehicleRepositoryProvider).deleteVehicle(id);
      if (!mounted) return;
      toaster.show(ShadToast(
        title: const Text('Vehicle deleted'),
        description: Text(
            '${vehicle.vehicleNumber} has been removed from the fleet.'),
      ));
      _refresh();
    } on VehicleApiException catch (e) {
      if (!mounted) return;
      toaster.show(ShadToast.destructive(
        title: const Text('Delete failed'),
        description: Text(e.message),
      ));
    } catch (_) {
      if (!mounted) return;
      toaster.show(const ShadToast.destructive(
        title: Text('Delete failed'),
        description: Text('An unexpected error occurred.'),
      ));
    }
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _searchQuery = '';
      _statusFilter = null;
      _filterResetCount++;
    });
  }

  Future<void> _logout() async {
    await AuthService.clearSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalCount = ref.watch(totalVehiclesCountProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 960;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _TopBar(
            totalCount: totalCount,
            username: AuthService.username ?? 'User',
            role: AuthService.role ?? 'USER',
            onRefresh: _refresh,
            onLogout: _logout,
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isWide ? 32 : 16,
                vertical: 20,
              ),
              child: Column(
                children: [
                  _FilterBar(
                    searchCtrl: _searchCtrl,
                    statusFilter: _statusFilter,
                    resetCount: _filterResetCount,
                    onSearch: (q) {
                      setState(() => _searchQuery = q);
                      _maybeLoadMore();
                    },
                    onStatusFilter: (s) {
                      setState(() => _statusFilter = s);
                      _maybeLoadMore();
                    },
                    onAdd: () => _openForm(),
                    onClear: _clearFilters,
                  ),
                  const SizedBox(height: 16),
                  Expanded(child: _buildList()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (!_initialLoadDone) {
      if (_error != null) {
        return _ErrorCard(error: _error, onRetry: _loadNextPage);
      }
      return _SkeletonList(isWide: MediaQuery.sizeOf(context).width >= 960);
    }
    if (_items.isEmpty) {
      return _EmptyState(onAdd: () => _openForm());
    }

    final visible = _items.where(_matchesFilter).toList();

    if (visible.isEmpty) {
      if (_hasNext && _error == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return _NoMatches(onClear: _clearFilters);
    }

    return ListView.separated(
      controller: _scrollCtrl,
      itemCount: visible.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        if (i < visible.length) {
          final vehicle = visible[i];
          return VehicleRowCard(
            key: ValueKey(vehicle.id),
            vehicle: vehicle,
            onEdit: () => _openForm(vehicle: vehicle),
            onDelete: () => _confirmDelete(vehicle),
          );
        }

        if (_error != null) {
          return _NewPageError(error: _error, onRetry: _loadNextPage);
        }
        if (_isLoading || _hasNext) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (_isFiltering) return const SizedBox.shrink();
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: Text(
              '— All vehicles loaded —',
              style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            ),
          ),
        );
      },
    );
  }
}



class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.totalCount,
    required this.username,
    required this.role,
    required this.onRefresh,
    required this.onLogout,
  });

  final int? totalCount;
  final String username;
  final String role;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
        ),
        boxShadow: [
          BoxShadow(
              color: Color(0x33000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.car,
                        size: 18, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Stark Group VMS',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (totalCount != null)
                        Text(
                          '$totalCount vehicles in fleet',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const Spacer(),


              ShadTooltip(
                builder: (_) => const Text('Refresh'),
                child: ShadIconButton.ghost(
                  onPressed: onRefresh,
                  icon:
                      const Icon(LucideIcons.refreshCw, size: 16, color: Color(0xFF64748B)),
                ),
              ),
              const SizedBox(width: 8),


              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.12)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.userCircle2,
                        size: 15, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 6),
                    Text(
                      username,
                      style: const TextStyle(
                          color: Color(0xFFCBD5E1), fontSize: 12),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                            color: Color(0xFF93C5FD), fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),


              ShadTooltip(
                builder: (_) => const Text('Sign out'),
                child: ShadIconButton.ghost(
                  onPressed: onLogout,
                  icon: const Icon(LucideIcons.logOut,
                      size: 16, color: Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.searchCtrl,
    required this.statusFilter,
    required this.resetCount,
    required this.onSearch,
    required this.onStatusFilter,
    required this.onAdd,
    required this.onClear,
  });

  final TextEditingController searchCtrl;
  final VehicleStatus? statusFilter;
  final int resetCount;
  final ValueChanged<String> onSearch;
  final ValueChanged<VehicleStatus?> onStatusFilter;
  final VoidCallback onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 720;
    final hasFilter = searchCtrl.text.isNotEmpty || statusFilter != null;

    final row = Row(
      children: [

        Expanded(
          flex: 3,
          child: ShadInput(
            controller: searchCtrl,
            placeholder: const Text('Search vehicles…'),
            leading: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10),
              child: Icon(LucideIcons.search, size: 15),
            ),
            onChanged: onSearch,
          ),
        ),
        const SizedBox(width: 10),


        ShadSelect<String>(
          key: ValueKey('status-filter-$resetCount'),
          minWidth: 170,
          initialValue: statusFilter?.name ?? 'all',
          allowDeselection: false,
          placeholder: const Text('All statuses'),
          selectedOptionBuilder: (_, v) => Text(
            v == 'all'
                ? 'All statuses'
                : VehicleStatus.values.firstWhere((s) => s.name == v).label,
          ),
          options: [
            const ShadOption(value: 'all', child: Text('All statuses')),
            ...VehicleStatus.values.map(
              (s) => ShadOption(value: s.name, child: Text(s.label)),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            onStatusFilter(
              v == 'all'
                  ? null
                  : VehicleStatus.values.firstWhere((s) => s.name == v),
            );
          },
        ),
        if (hasFilter) ...[
          const SizedBox(width: 8),
          ShadButton.outline(
            key: const ValueKey('clear-btn'),
            onPressed: onClear,
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.x, size: 13),
            child: const Text('Clear'),
          ),
        ],
        const SizedBox(width: 10),

        // Add button
        ShadButton(
          key: const ValueKey('add-btn'),
          onPressed: onAdd,
          leading: const Icon(LucideIcons.plus, size: 15),
          child: const Text('Add Vehicle'),
        ),
      ],
    );

    return row;
  }
}

// ── Skeleton ─────────────────────────────────────────────────────────────────

class _SkeletonList extends StatelessWidget {
  const _SkeletonList({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 6,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => VehicleRowCard(
          vehicle: VehicleRowCard.placeholderVehicle,
          onEdit: () {},
          onDelete: () {},
        ),
      ),
    );
  }
}


class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: ShadCard(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary,
                  shape: BoxShape.circle,
                ),
                child: Icon(LucideIcons.truck,
                    size: 36, color: theme.colorScheme.foreground),
              ),
              const SizedBox(height: 20),
              Text('No vehicles yet', style: theme.textTheme.h3),
              const SizedBox(height: 8),
              Text(
                'Add the first vehicle to your Stark Group fleet.',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ShadButton(
                onPressed: onAdd,
                leading: const Icon(LucideIcons.plus, size: 16),
                child: const Text('Register Vehicle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final message = error is VehicleApiException
        ? (error as VehicleApiException).message
        : 'Unable to load vehicles. Check that the backend is running.';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ShadCard(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.wifiOff,
                  size: 32, color: theme.colorScheme.destructive),
              const SizedBox(height: 16),
              Text('Could not load vehicles', style: theme.textTheme.h4),
              const SizedBox(height: 8),
              Text(message,
                  style: theme.textTheme.muted, textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ShadButton(
                  onPressed: onRetry,
                  leading: const Icon(LucideIcons.refreshCw, size: 15),
                  child: const Text('Retry')),
            ],
          ),
        ),
      ),
    );
  }
}

class _NewPageError extends StatelessWidget {
  const _NewPageError({required this.error, required this.onRetry});

  final Object? error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final msg = error is VehicleApiException
        ? (error as VehicleApiException).message
        : 'Failed to load more vehicles.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ShadAlert.destructive(
        icon: const Icon(LucideIcons.circleAlert),
        title: const Text('Pagination error'),
        description: Row(
          children: [
            Expanded(child: Text(msg)),
            const SizedBox(width: 12),
            ShadButton.outline(
                size: ShadButtonSize.sm,
                onPressed: onRetry,
                child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}


class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.search, size: 32, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No vehicles match your search or filter.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ShadButton.outline(
            onPressed: onClear,
            child: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }
}
