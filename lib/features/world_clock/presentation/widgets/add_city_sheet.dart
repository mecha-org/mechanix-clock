import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../../core/theme/app_theme.dart';
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

  String _formatTimezoneOffset(String timezoneId) {
    try {
      final location = tz.getLocation(timezoneId);
      final now = tz.TZDateTime.now(location);
      final offset = now.timeZoneOffset;
      final hours = offset.inHours;
      final minutes = offset.inMinutes.remainder(60).abs();
      final sign = hours >= 0 ? '+' : '−';
      final hoursStr = hours.abs().toString().padLeft(2, '0');
      final minutesStr = minutes.toString().padLeft(2, '0');
      return 'UTC$sign$hoursStr:$minutesStr';
    } catch (e) {
      return 'UTC+00:00';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filteredCities = worldCities.where((city) {
      final query = _searchQuery.toLowerCase();
      return city.name.toLowerCase().contains(query) ||
          city.country.toLowerCase().contains(query) ||
          city.timezoneId.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Right Close Icon
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: IconButton(
                  key: const Key('add_city_close_button'),
                  icon: const Icon(
                    Icons.close,
                    color: AppColors.textPrimary,
                    size: 28,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            // Cities List
            Expanded(
              child: filteredCities.isEmpty
                  ? Center(
                      child: Text(
                        l10n.no_cities_found,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textGrey,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: filteredCities.length,
                      separatorBuilder: (context, index) => Divider(
                        color: AppColors.textPrimary.withValues(alpha: 0.08),
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        final offsetStr = _formatTimezoneOffset(
                          city.timezoneId,
                        );
                        return ListTile(
                          key: Key(
                            'add_city_tile_${city.name.replaceAll(' ', '_')}',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 8,
                          ),
                          title: Text(
                            '${city.name}, ${city.country}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '$offsetStr • ${city.timezoneId.replaceAll('_', ' ')}',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    fontSize: 14,
                                    color: AppColors.textGrey,
                                  ),
                            ),
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
                      },
                    ),
            ),
            // Sticky Bottom Search Bar
            Container(
              color: AppColors.surface,
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.border.withValues(alpha: 0.5),
                    width: 0.5,
                  ),
                ),
                child: TextField(
                  key: const Key('add_city_search_field'),
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  style: Theme.of(context).textTheme.bodyMedium,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textGrey,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.cancel_rounded,
                              color: AppColors.textGrey,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    hintText: l10n.search_country_region,
                    hintStyle: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.textDim),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
