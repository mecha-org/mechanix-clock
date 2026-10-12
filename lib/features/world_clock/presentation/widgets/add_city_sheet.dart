import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mechanix_clock/core/utils/icons.dart';
import 'package:widgets/widgets.dart';

import '../../../../l10n/app_localizations.dart';
import '../../bloc/world_clock_bloc.dart';
import '../../bloc/world_clock_event.dart';
import '../../data/models/city_model.dart';

class AddCitySheet extends StatefulWidget {
  const AddCitySheet({super.key});

  @override
  State<AddCitySheet> createState() => _AddCitySheetState();
}

class _AddCitySheetState extends State<AddCitySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final screenHeight = MediaQuery.of(context).size.height;

    final filteredCities = worldCities.where((city) {
      final query = _searchQuery.toLowerCase();
      return city.name.toLowerCase().contains(query) ||
          city.country.toLowerCase().contains(query) ||
          city.timezoneId.toLowerCase().contains(query);
    }).toList();

    return SizedBox(
      height: screenHeight * 0.85,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          children: [
            MechanixSearchBar(
              key: const Key('add_city_search_field'),
              controller: _searchController,
              hintText: l10n.search_country_region,
              textStyle: WidgetStatePropertyAll(
                theme.textTheme.titleLarge?.copyWith(fontSize: 20),
              ),
              hintStyle: WidgetStatePropertyAll(
                theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              leading: ImageIcon(
                const AssetImage(ClockIcons.search),
                color: theme.colorScheme.onSurface,
                size: 24,
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              trailing: _searchQuery.isNotEmpty
                  ? [
                      MechanixIconButton.standard(
                        type: IconButtonType.rounded,
                        icon: ImageIcon(
                          const AssetImage(ClockIcons.cancel),
                          color: theme.colorScheme.onSurface,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      ),
                    ]
                  : null,
            ),

            const SizedBox(height: 12),
            // Cities List
            Expanded(
              child: filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        l10n.no_cities_found,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: filteredCities.length,
                      separatorBuilder: (context, index) =>
                          MechanixDivider(color: colorScheme.outline, space: 1),
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return _CityListTile(
                          city: city,
                          searchQuery: _searchQuery,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityListTile extends StatelessWidget {
  final City city;
  final String searchQuery;

  const _CityListTile({
    required this.city,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final fullCityText = '${city.name}, ${city.country}';

    return MechanixListTile(
      key: Key('add_city_tile_${city.name.replaceAll(' ', '_')}'),
      labelText: fullCityText,
      label: _HighlightedCityText(
        text: fullCityText,
        query: searchQuery,
      ),
      onTap: () {
        context.read<WorldClockBloc>().add(
          AddWorldClock(
            cityName: city.name,
            country: city.country,
            timezoneId: city.timezoneId,
          ),
        );
        Navigator.pop(context);
      },
    );
  }
}

class _HighlightedCityText extends StatelessWidget {
  final String text;
  final String query;

  const _HighlightedCityText({
    required this.text,
    required this.query,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (query.isEmpty) {
      return Text(text, style: theme.textTheme.titleLarge);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final index = lowerText.indexOf(lowerQuery);

    if (index == -1) {
      return Text(
        text,
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
      );
    }

    final before = text.substring(0, index);
    final match = text.substring(index, index + query.length);
    final after = text.substring(index + query.length);

    return RichText(
      text: TextSpan(
        style: theme.textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w400,
        ),
        children: [
          if (before.isNotEmpty) TextSpan(text: before),
          TextSpan(
            text: match,
            style: TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (after.isNotEmpty) TextSpan(text: after),
        ],
      ),
    );
  }
}
