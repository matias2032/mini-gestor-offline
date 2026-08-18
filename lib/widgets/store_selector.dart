// lib/widgets/store_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/business_unit_model.dart';
import '../providers/business_unit_provider.dart';
import 'package:mini/l10n/app_localizations.dart';

/// Store switcher shown in the Dashboard AppBar. Renders nothing when
/// there's only one store — a switcher with a single option is dead UI.
class StoreSelector extends StatelessWidget {
  const StoreSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final businessUnitProvider = context.watch<BusinessUnitProvider>();
    if (!businessUnitProvider.hasMultipleUnits) return const SizedBox.shrink();

    final activeUnit = businessUnitProvider.activeBusinessUnit;
    final loc = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return PopupMenuButton<BusinessUnitModel>(
      tooltip: loc.switchStoreTooltip,
      onSelected: (unit) => context.read<BusinessUnitProvider>().setActiveUnit(unit),
      itemBuilder: (context) => businessUnitProvider.units
          .map(
            (unit) => PopupMenuItem<BusinessUnitModel>(
              value: unit,
              child: Row(
                children: [
                  Icon(
                    Icons.check,
                    size: 18,
                    color: unit.idBusinessUnit == activeUnit?.idBusinessUnit
                        ? colorScheme.primary
                        : Colors.transparent,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(unit.name, overflow: TextOverflow.ellipsis)),
                ],
              ),
            ),
          )
          .toList(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.storefront_outlined, size: 20),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 110),
              child: Text(
                activeUnit?.name ?? '',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}