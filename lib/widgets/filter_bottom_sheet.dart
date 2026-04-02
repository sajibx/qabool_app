import 'package:flutter/material.dart';
import 'package:qabool_app/theme.dart';

class FilterBottomSheet extends StatefulWidget {
  final RangeValues initialAgeRange;
  final String? initialReligion;
  final String? initialEducation;
  final String? initialLocation;
  final bool initialShowConnected;
  final bool initialShowSkipped;
  final bool isPopover;
  final Function(
    RangeValues ageRange,
    String? religion,
    String? education,
    String? location,
    bool showConnected,
    bool showSkipped,
  ) onApply;

  const FilterBottomSheet({
    super.key,
    required this.initialAgeRange,
    required this.initialReligion,
    required this.initialEducation,
    required this.initialLocation,
    required this.initialShowConnected,
    required this.initialShowSkipped,
    required this.onApply,
    this.isPopover = false,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late RangeValues _ageRange;
  String? _selectedReligion;
  String? _selectedEducation;
  String? _selectedLocation;
  bool _showConnected = false;
  bool _showSkipped = false;

  final List<String> religions = [
    'Islam (Sunni)',
    'Islam (Shia)',
    'Islam (Other)',
    'Christianity',
    'Hinduism',
    'Sikhism',
    'Buddhism',
    'Other'
  ];

  final List<String> educationLevels = [
    'High School',
    'Bachelor\'s',
    'Master\'s',
    'PhD',
    'Other'
  ];

  final List<String> locations = [
    'London',
    'New York',
    'Dhaka',
    'Dubai',
    'Toronto',
    'Sydney'
  ];

  @override
  void initState() {
    super.initState();
    _ageRange = widget.initialAgeRange;
    _selectedReligion = widget.initialReligion;
    _selectedEducation = widget.initialEducation;
    _selectedLocation = widget.initialLocation;
    _showConnected = widget.initialShowConnected;
    _showSkipped = widget.initialShowSkipped;
  }

  void _resetFilters() {
    setState(() {
      _ageRange = const RangeValues(18, 80);
      _selectedReligion = null;
      _selectedEducation = null;
      _selectedLocation = null;
      _showConnected = false;
      _showSkipped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = QaboolTheme.primary;

    return Container(
      padding: const EdgeInsets.only(top: 16, left: 24, right: 24, bottom: 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: widget.isPopover 
            ? BorderRadius.circular(24) 
            : const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: widget.isPopover 
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          if (!widget.isPopover)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          const SizedBox(height: 24),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: _resetFilters,
                child: Text('Reset', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Age Range
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Age Range', style: TextStyle(fontWeight: FontWeight.w600)),
                      Text('${_ageRange.start.toInt()} - ${_ageRange.end.toInt()}'),
                    ],
                  ),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 80,
                    divisions: 62,
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    activeColor: primaryColor,
                    onChanged: (values) {
                      setState(() => _ageRange = values);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Religion Dropdown
                  _buildDropdown('Religion', religions, _selectedReligion, (val) {
                    setState(() => _selectedReligion = val);
                  }, isDark),
                  const SizedBox(height: 16),

                  // Education Dropdown
                  _buildDropdown('Education', educationLevels, _selectedEducation, (val) {
                    setState(() => _selectedEducation = val);
                  }, isDark),
                  const SizedBox(height: 16),

                  // Location Dropdown
                  _buildDropdown('Location', locations, _selectedLocation, (val) {
                    setState(() => _selectedLocation = val);
                  }, isDark),
                  const SizedBox(height: 24),

                  // Toggles
                  _buildToggle('Show Connected', _showConnected, (val) {
                    setState(() => _showConnected = val);
                  }, isDark),
                  const SizedBox(height: 12),
                  _buildToggle('Show Skipped', _showSkipped, (val) {
                    setState(() => _showSkipped = val);
                  }, isDark),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),

          // Apply Button
          ElevatedButton(
            onPressed: () {
              widget.onApply(
                _ageRange,
                _selectedReligion,
                _selectedEducation,
                _selectedLocation,
                _showConnected,
                _showSkipped,
              );
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String? selectedItem,
    Function(String?) onChanged,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
             color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
             borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: selectedItem,
              hint: const Text('Any'),
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('Any'),
                ),
                ...items.map((item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item),
                  );
                }),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, Function(bool) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: QaboolTheme.primary,
          ),
        ],
      ),
    );
  }
}
