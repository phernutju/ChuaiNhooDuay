import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../constants/constants.dart';
import '../../models/request_model.dart';
import 'requester_controller.dart';

class NewRequestScreen extends ConsumerStatefulWidget {
  const NewRequestScreen({super.key});

  @override
  ConsumerState<NewRequestScreen> createState() => _NewRequestScreenState();
}

class _NewRequestScreenState extends ConsumerState<NewRequestScreen> {
  final _descController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  static const _latMin = -90.0;
  static const _latMax = 90.0;
  static const _lngMin = -180.0;
  static const _lngMax = 180.0;

  static bool _isValidLat(String s) {
    final v = double.tryParse(s);
    return v != null && v >= _latMin && v <= _latMax;
  }

  static bool _isValidLng(String s) {
    final v = double.tryParse(s);
    return v != null && v >= _lngMin && v <= _lngMax;
  }

  bool get _coordsValid =>
      _isValidLat(_latController.text) && _isValidLng(_lngController.text);

  void _trySetManualFromFields() {
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    if (lat != null &&
        lng != null &&
        lat >= _latMin &&
        lat <= _latMax &&
        lng >= _lngMin &&
        lng <= _lngMax) {
      ref.read(requesterControllerProvider.notifier).setManualLocation(
            lat,
            lng,
            '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}',
          );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(requesterControllerProvider.notifier).fetchCurrentLocation();
    });
  }

  @override
  void dispose() {
    _descController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    ref
        .read(requesterControllerProvider.notifier)
        .setDescription(_descController.text.trim());
    try {
      final count = await ref
          .read(requesterControllerProvider.notifier)
          .submitRequest();
      if (mounted) {
        context.pushNamed('request-posted', extra: count);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post: $e'),
            backgroundColor: kCriticalColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(requesterControllerProvider);

    ref.listen<RequesterState>(requesterControllerProvider, (prev, next) {
      if (next.coordinates != null && prev?.coordinates != next.coordinates) {
        final newLat = next.coordinates!.latitude.toStringAsFixed(5);
        final newLng = next.coordinates!.longitude.toStringAsFixed(5);
        if (_latController.text != newLat || _lngController.text != newLng) {
          _latController.text = newLat;
          _lngController.text = newLng;
          setState(() {});
        }
      }
    });

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New request',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              '4 STEPS · UNDER A MINUTE',
              style: TextStyle(
                  color: kTextSecondary, fontSize: 10, letterSpacing: 0.8),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(number: '1', title: 'What do you need?'),
            const SizedBox(height: 12),
            _CategoryGrid(selected: state.selectedCategory),
            const SizedBox(height: 20),
            _SectionHeader(number: '2', title: 'Describe your situation'),
            const SizedBox(height: 10),
            _DescriptionField(controller: _descController),
            const SizedBox(height: 24),
            _SectionHeader(number: '3', title: 'How urgent?'),
            const SizedBox(height: 12),
            _UrgencyPicker(selected: state.urgency),
            const SizedBox(height: 24),
            _SectionHeader(number: '4', title: 'Location'),
            const SizedBox(height: 12),
            _LocationCard(state: state),
            const SizedBox(height: 8),
            _LatLngFields(
              latController: _latController,
              lngController: _lngController,
              latError: _latController.text.isNotEmpty &&
                  !_isValidLat(_latController.text),
              lngError: _lngController.text.isNotEmpty &&
                  !_isValidLng(_lngController.text),
              onChanged: () {
                setState(() {});
                _trySetManualFromFields();
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _SubmitBar(
        state: state,
        onSubmit: _submit,
        coordsValid: _coordsValid,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  const _SectionHeader({required this.number, required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: kPrimaryBlue,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _CategoryGrid extends ConsumerWidget {
  final RequestType? selected;
  const _CategoryGrid({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = [
      (RequestType.medical, Icons.medical_services_outlined, 'Medical'),
      (RequestType.shelter, Icons.home_outlined, 'Shelter'),
      (RequestType.water, Icons.water_drop_outlined, 'Food /\nWater'),
      (RequestType.transport, Icons.directions_bus_outlined, 'Transport'),
      (RequestType.rescue, Icons.health_and_safety_outlined, 'Rescue'),
      (RequestType.evacuate, Icons.exit_to_app_outlined, 'Evacuate'),
      (RequestType.supplies, Icons.inventory_2_outlined, 'Supplies'),
      (RequestType.other, Icons.more_horiz, 'Other'),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: categories.map((item) {
        final isSelected = selected == item.$1;
        return GestureDetector(
          onTap: () => ref
              .read(requesterControllerProvider.notifier)
              .selectCategory(item.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: isSelected
                  ? kPrimaryBlue.withValues(alpha:0.25)
                  : kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? kPrimaryBlue : kBorderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.$2,
                  color: isSelected ? kPrimaryBlue : Colors.white70,
                  size: 22,
                ),
                const SizedBox(height: 4),
                Text(
                  item.$3,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: isSelected ? kPrimaryBlue : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _DescriptionField extends StatelessWidget {
  final TextEditingController controller;
  const _DescriptionField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Briefly describe what you need — e.g. "someone to help support an elderly woman who fell" ...',
        hintStyle: TextStyle(color: kTextSecondary, fontSize: 13),
        filled: true,
        fillColor: kCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimaryBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

class _UrgencyPicker extends ConsumerWidget {
  final UrgencyLevel selected;
  const _UrgencyPicker({required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (
        UrgencyLevel.critical,
        Icons.local_hospital_outlined,
        'Critical',
        'Life-safety · respond in 15 min',
        kCriticalColor,
      ),
      (
        UrgencyLevel.urgent,
        Icons.warning_amber_outlined,
        'Urgent',
        'Needs help today',
        kUrgentColor,
      ),
      (
        UrgencyLevel.general,
        Icons.nature_people_outlined,
        'General',
        'Flexible timing',
        kGeneralColor,
      ),
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = selected == opt.$1;
        return GestureDetector(
          onTap: () => ref
              .read(requesterControllerProvider.notifier)
              .setUrgency(opt.$1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? opt.$5.withValues(alpha:0.12)
                  : kCardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? opt.$5 : kBorderColor,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(opt.$2,
                    color: isSelected ? opt.$5 : Colors.white54, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opt.$3,
                        style: TextStyle(
                            color: isSelected ? opt.$5 : Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        opt.$4,
                        style: TextStyle(
                            color: isSelected
                                ? opt.$5.withValues(alpha:0.7)
                                : kTextSecondary,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, color: opt.$5, size: 20)
                else
                  Icon(Icons.radio_button_unchecked,
                      color: kTextSecondary, size: 20),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _LocationCard extends ConsumerWidget {
  final RequesterState state;
  const _LocationCard({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on_outlined,
              color: kPrimaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: state.isLocationLoading
                ? const Text('Fetching location...',
                    style: TextStyle(color: Colors.white70, fontSize: 13))
                : state.coordinates != null
                    ? Text(
                        state.locationAddress,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        state.error ?? 'Location unavailable',
                        style: TextStyle(
                            color: state.error != null
                                ? kCriticalColor
                                : kTextSecondary,
                            fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
          ),
          if (state.isLocationLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: kPrimaryBlue),
            )
          else
            GestureDetector(
              onTap: () => ref
                  .read(requesterControllerProvider.notifier)
                  .fetchCurrentLocation(),
              child: const Icon(Icons.refresh, color: kPrimaryBlue, size: 20),
            ),
        ],
      ),
    );
  }
}


class _LatLngFields extends StatelessWidget {
  final TextEditingController latController;
  final TextEditingController lngController;
  final bool latError;
  final bool lngError;
  final VoidCallback onChanged;

  static const _latLabel = 'Latitude';
  static const _lngLabel = 'Longitude';
  static const _latHint = '-90 to 90';
  static const _lngHint = '-180 to 180';
  static const _latErrMsg = 'Must be -90 to 90';
  static const _lngErrMsg = 'Must be -180 to 180';

  const _LatLngFields({
    required this.latController,
    required this.lngController,
    required this.latError,
    required this.lngError,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _CoordField(
            controller: latController,
            label: _latLabel,
            hint: _latHint,
            errorText: latError ? _latErrMsg : null,
            onChanged: (_) => onChanged(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _CoordField(
            controller: lngController,
            label: _lngLabel,
            hint: _lngHint,
            errorText: lngError ? _lngErrMsg : null,
            onChanged: (_) => onChanged(),
          ),
        ),
      ],
    );
  }
}

class _CoordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? errorText;
  final ValueChanged<String> onChanged;

  const _CoordField({
    required this.controller,
    required this.label,
    required this.hint,
    this.errorText,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(
        signed: true,
        decimal: true,
      ),
      style: TextStyle(color: Colors.white, fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: kTextSecondary, fontSize: 12),
        hintText: hint,
        hintStyle: TextStyle(color: kTextSecondary, fontSize: 12),
        errorText: errorText,
        errorStyle: TextStyle(color: kCriticalColor, fontSize: 10),
        filled: true,
        fillColor: kCardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: kBorderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: hasError ? kCriticalColor : kBorderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
              color: hasError ? kCriticalColor : kPrimaryBlue),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onChanged: onChanged,
    );
  }
}

class _SubmitBar extends StatelessWidget {
  final RequesterState state;
  final VoidCallback onSubmit;
  final bool coordsValid;
  const _SubmitBar({
    required this.state,
    required this.onSubmit,
    this.coordsValid = true,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: (state.canSubmit && coordsValid) ? onSubmit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: kCriticalColor,
              disabledBackgroundColor: kCardColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: state.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child:
                        CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Text(
                    'Post request',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
          ),
        ),
      ),
    );
  }
}
