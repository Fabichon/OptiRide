import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:optiride/providers.dart';
import 'package:optiride/core/models/place_suggestion.dart';

class DestinationAutocompleteField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final String label;
  final void Function(PlaceSuggestion suggestion)? onSelected;
  const DestinationAutocompleteField({super.key, required this.controller, this.label = 'Destination', this.onSelected});

  @override
  ConsumerState<DestinationAutocompleteField> createState() => _DestinationAutocompleteFieldState();
}

class _DestinationAutocompleteFieldState extends ConsumerState<DestinationAutocompleteField> {
  final LayerLink _link = LayerLink();
  OverlayEntry? _entry;
  bool _loadingDetails = false;

  Future<void> _selectSuggestion(PlaceSuggestion s) async {
    setState(() => _loadingDetails = true);
    widget.controller.text = s.mainText;
    ref.read(destinationQueryProvider.notifier).state = s.mainText;
    final svc = ref.read(placesServiceProvider);
    final details = await svc.details(s.placeId).catchError((_) => null);
    ref.read(destinationQueryProvider.notifier).state = s.mainText;
    // Mettre à jour SearchQuery global si présent
    final q = ref.read(searchQueryProvider);
    ref.read(searchQueryProvider.notifier).state = q.copyWith(
      destinationAddress: details?.formattedAddress ?? s.mainText,
      destinationLat: details?.lat,
      destinationLng: details?.lng,
    );
    widget.controller.text = details?.formattedAddress ?? s.mainText;
    widget.onSelected?.call(s);
    setState(() => _loadingDetails = false);
  }

  void _openOverlay() {
    _closeOverlay();
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: (ctx) {
      final suggestionsAsync = ref.watch(placeSuggestionsProvider);
      final size = (context.findRenderObject() as RenderBox?)?.size ?? Size.zero;
      return Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _link,
          offset: Offset(0, size.height + 4),
          showWhenUnlinked: false,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: suggestionsAsync.when(
                data: (items) {
                  final limited = items.take(6).toList();
                  if (ref.read(destinationQueryProvider).trim().isNotEmpty && limited.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('Aucune suggestion'),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.zero,
                    shrinkWrap: true,
                    itemCount: limited.length,
                    itemBuilder: (c, i) {
                      final s = limited[i];
                      return ListTile(
                        title: Text(s.mainText),
                        subtitle: Text(s.secondaryText),
                        onTap: () {
                          _closeOverlay();
                          _selectSuggestion(s);
                        },
                      );
                    },
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                error: (e, st) => const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Erreur'),
                ),
              ),
            ),
          ),
        ),
      );
    });
    overlay.insert(_entry!);
  }

  void _closeOverlay() {
    _entry?.remove();
    _entry = null;
  }

  @override
  void dispose() {
    _closeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          labelText: widget.label,
          suffixIcon: _loadingDetails ? const SizedBox(width: 18, height: 18, child: Padding(padding: EdgeInsets.all(4), child: CircularProgressIndicator(strokeWidth: 2))) : null,
        ),
        onChanged: (v) {
          ref.read(destinationQueryProvider.notifier).state = v;
          if (v.isEmpty) {
            _closeOverlay();
          } else {
            _openOverlay();
          }
        },
      ),
    );
  }
}
