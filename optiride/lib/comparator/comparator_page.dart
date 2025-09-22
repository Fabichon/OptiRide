import 'dart:async';

import 'package:flutter/material.dart';
import 'package:optiride/comparator/utils.dart';

import 'package:optiride/comparator/models.dart';
import 'package:optiride/comparator/controller.dart';
import 'package:optiride/comparator/mock_repository.dart';

class ComparatorPage extends StatefulWidget {
  const ComparatorPage({
    super.key,
    required this.originLat,
    required this.originLng,
    required this.destLat,
    required this.destLng,
    required this.when,
  this.distanceMeters,
  this.durationSeconds,
  });

  final double originLat;
  final double originLng;
  final double destLat;
  final double destLng;
  final DateTime when;
  final double? distanceMeters;
  final int? durationSeconds;

  @override
  State<ComparatorPage> createState() => _ComparatorPageState();
}

class _ComparatorPageState extends State<ComparatorPage> {
  late final ComparatorController controller;

  static const _primary = Color(0xFF64A9A7);
  static const _primaryHover = Color(0xFF4F8E8C);
  static const _pillInactiveBg = Color(0xFFF7F9FA);
  static const _pillInactiveFg = Color(0xFF6B7280);
  static const _cardBorder = Color(0xFFE5E7EB);

  @override
  void initState() {
    super.initState();
    controller = ComparatorController(repo: RideOffersRepository());
    // Init + auto-refresh 3s
    unawaited(controller.init(
      originLat: widget.originLat,
      originLng: widget.originLng,
      destLat: widget.destLat,
      destLng: widget.destLng,
      when: widget.when,
    ));
    controller.startAutoRefresh(const Duration(seconds: 3));
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        title: const Text('Comparateur'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return Column(
            children: [
              const SizedBox(height: 8),
              _buildTripSummary(),
              const SizedBox(height: 8),
              _buildSortSegmented(),
              const SizedBox(height: 8),
              _buildCategoryPills(),
              const SizedBox(height: 8),
              _buildRefreshingBanner(),
              const SizedBox(height: 8),
              Expanded(child: _buildList()),
            ],
          );
        },
      ),
    );
  }

  // --- UI sections ---
  Widget _buildSortSegmented() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SegmentedButton<ComparatorSort>(
  segments: const [
          ButtonSegment(
            value: ComparatorSort.cheapest,
            label: Text('Moins chers'),
          ),
          ButtonSegment(
            value: ComparatorSort.fastest,
            label: Text('Plus rapides'),
          ),
        ],
        selected: {controller.sort},
        onSelectionChanged: (selection) {
          if (selection.isNotEmpty) {
            controller.setSort(selection.first);
          }
        },
        showSelectedIcon: false,
        style: const ButtonStyle(
          shape: WidgetStatePropertyAll(RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          )),
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    final cats = [
      RideCategory.all,
      RideCategory.standard,
      RideCategory.premium,
      RideCategory.xl,
      RideCategory.pet,
      RideCategory.woman,
    ];

    return SizedBox(
      height: 50,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final c = cats[index];
          final selected = controller.category == c;
          final bg = selected ? _primary.withValues(alpha: 0.10) : _pillInactiveBg;
          final fg = selected ? _primary : _pillInactiveFg;
          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => controller.setCategory(c),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: selected ? _primary : _cardBorder),
              ),
              child: Center(
                child: Text(
                  _categoryLabel(c),
                  style: TextStyle(
                    color: fg,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRefreshingBanner() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: controller.refreshing
          ? Padding(
              key: const ValueKey('refreshing'),
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _primary.withValues(alpha: 0.25)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rafraîchissement des offres…',
                      style: TextStyle(color: _primaryHover, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: const LinearProgressIndicator(minHeight: 4),
                    ),
                  ],
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTripSummary() {
    final d = widget.distanceMeters;
    final s = widget.durationSeconds;
    if (d == null && s == null) return const SizedBox.shrink();

    String? km;
    if (d != null) {
      final kmVal = d / 1000.0;
      km = kmVal >= 10 ? kmVal.toStringAsFixed(0) : kmVal.toStringAsFixed(1);
    }
    int? mins;
    if (s != null) {
      mins = (s / 60).round();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container
      (
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.route, color: _primary),
            const SizedBox(width: 8),
            if (km != null) Text('$km km', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (km != null && mins != null) const SizedBox(width: 12),
            if (mins != null) Text('~$mins min', style: TextStyle(color: Colors.grey.shade700)),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = controller.visible;
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Aucune offre pour cette catégorie. Réessayez.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => controller.setCategory(controller.category),
                child: const Text('Rafraîchir'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final o = items[index];
        return _offerCard(o);
      },
    );
  }

  Widget _offerCard(RideOffer o) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: _cardBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _platformAvatar(o.platform),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        platformDisplayName(o.platform),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${o.capacityMin}–${o.capacityMax} | attente ${o.etaMin} min',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 6),
                      _categoryChip(o.category),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  formatPriceEUR(o.priceMinCents),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => openDeepLinkOrWeb(appUri: o.deeplinkApp, webUrl: o.deeplinkWeb),
                child: const Text('Réserver'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _platformAvatar(String platform) {
    final letter = platform.isNotEmpty ? platform[0].toUpperCase() : '?';
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
  color: _primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
  border: Border.all(color: _primary.withValues(alpha: 0.35)),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: const TextStyle(fontWeight: FontWeight.bold, color: _primary),
      ),
    );
  }

  // platformDisplayName déplacé dans utils.dart

  Widget _categoryChip(RideCategory c) {
    final label = _categoryLabel(c);
    return Container(
      decoration: BoxDecoration(
  color: _primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
  border: Border.all(color: _primary.withValues(alpha: 0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(color: _primary, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _categoryLabel(RideCategory c) {
    switch (c) {
      case RideCategory.all:
        return 'All';
      case RideCategory.standard:
        return 'Standard';
      case RideCategory.premium:
        return 'Premium';
      case RideCategory.xl:
        return 'XL';
      case RideCategory.pet:
        return 'Pet';
      case RideCategory.woman:
        return 'Woman';
    }
  }

  // formatPriceEUR et openDeepLinkOrWeb déplacés dans utils.dart
}
