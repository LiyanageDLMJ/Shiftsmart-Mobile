import 'package:flutter/material.dart';
import 'package:shiftsmart/utils/country_dial_codes.dart';

class CountryCodePhoneField extends StatefulWidget {
  final String label;
  final TextEditingController controller;
  final String? errorText;
  final double labelFontSize;
  final Color fillColor;
  final ValueChanged<String>? onChanged;

  const CountryCodePhoneField({
    super.key,
    required this.label,
    required this.controller,
    this.errorText,
    this.labelFontSize = 16,
    this.fillColor = const Color(0x33FFFFFF),
    this.onChanged,
  });

  @override
  State<CountryCodePhoneField> createState() => _CountryCodePhoneFieldState();
}

class _CountryCodePhoneFieldState extends State<CountryCodePhoneField> {
  static final List<_CountryCode> _countries = countryDialCodes
      .map((country) => _CountryCode(
            country.name,
            country.dialCode,
            country.flag,
          ))
      .toList(growable: false);
  static final List<_CountryCode> _countriesByDialCodeLength = [
    ..._countries,
  ]..sort((a, b) => b.dialCode.length.compareTo(a.dialCode.length));

  final LayerLink _layerLink = LayerLink();
  final TextEditingController _searchController = TextEditingController();
  late _CountryCode _selectedCountry;
  late final TextEditingController _localNumberController;
  OverlayEntry? _dropdownEntry;
  bool _updatingExternalController = false;

  @override
  void initState() {
    super.initState();
    _selectedCountry = _countries.first;
    _localNumberController = TextEditingController();
    _syncFromExternalController();
  }

  @override
  void didUpdateWidget(covariant CountryCodePhoneField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_updatingExternalController) return;

    final composedNumber = _composeNumber(_localNumberController.text);
    if (widget.controller.text.trim() != composedNumber) {
      _syncFromExternalController();
    }
  }

  @override
  void dispose() {
    _removeDropdown();
    _searchController.dispose();
    _localNumberController.dispose();
    super.dispose();
  }

  void _syncFromExternalController() {
    final rawNumber = widget.controller.text.trim();
    final country = _detectCountry(rawNumber) ?? _countries.first;
    final localNumber = _stripCountryCode(rawNumber, country);

    if (mounted) {
      setState(() {
        _selectedCountry = country;
        _localNumberController.text = localNumber;
      });
    } else {
      _selectedCountry = country;
      _localNumberController.text = localNumber;
    }

    if (rawNumber.isNotEmpty && rawNumber != _composeNumber(localNumber)) {
      _setExternalNumber(localNumber);
    }
  }

  _CountryCode? _detectCountry(String value) {
    if (!value.startsWith('+')) return null;
    for (final country in _countriesByDialCodeLength) {
      if (value.startsWith(country.dialCode)) return country;
    }
    return null;
  }

  String _stripCountryCode(String value, _CountryCode country) {
    var normalized = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (normalized.startsWith(country.dialCode)) {
      normalized = normalized.substring(country.dialCode.length);
    }
    if (!value.startsWith('+')) {
      normalized = normalized.replaceFirst(RegExp(r'^0+'), '');
    }
    return normalized;
  }

  String _composeNumber(String localNumber) {
    final digits = localNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';
    return '${_selectedCountry.dialCode}$digits';
  }

  void _setExternalNumber(String localNumber) {
    _updatingExternalController = true;
    final fullNumber = _composeNumber(localNumber);
    widget.controller.text = fullNumber;
    _updatingExternalController = false;
    widget.onChanged?.call(fullNumber);
  }

  void _removeDropdown() {
    _dropdownEntry?.remove();
    _dropdownEntry = null;
    _searchController.clear();
  }

  void _toggleDropdown(double width) {
    if (_dropdownEntry != null) {
      _removeDropdown();
      return;
    }
    _showDropdown(width);
  }

  void _showDropdown(double width) {
    _dropdownEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: _removeDropdown,
                child: const SizedBox.expand(),
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 56),
              child: Material(
                color: Colors.transparent,
                child: SizedBox(
                  width: width,
                  child: _CountryDropdown(
                    countries: _countries,
                    selectedCountry: _selectedCountry,
                    searchController: _searchController,
                    onSelected: (country) {
                      setState(() => _selectedCountry = country);
                      _setExternalNumber(_localNumberController.text);
                      _removeDropdown();
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_dropdownEntry!);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.label,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: widget.labelFontSize,
                ),
              ),
              const SizedBox(height: 8),
              CompositedTransformTarget(
                link: _layerLink,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleDropdown(constraints.maxWidth),
                      child: Container(
                        width: 78,
                        height: 50,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFF24376E),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF5B86FF),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _selectedCountry.dialCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          color: widget.fillColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: error != null
                                ? Colors.redAccent
                                : Colors.white38,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _localNumberController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                          onChanged: _setExternalNumber,
                          decoration: const InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: InputBorder.none,
                            hintText: 'Phone number',
                            hintStyle: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.error_outline,
                      color: Colors.redAccent, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      error,
                      style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ]),
              ],
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}

class _CountryDropdown extends StatefulWidget {
  final List<_CountryCode> countries;
  final _CountryCode selectedCountry;
  final TextEditingController searchController;
  final ValueChanged<_CountryCode> onSelected;

  const _CountryDropdown({
    required this.countries,
    required this.selectedCountry,
    required this.searchController,
    required this.onSelected,
  });

  @override
  State<_CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<_CountryDropdown> {
  @override
  Widget build(BuildContext context) {
    final query = widget.searchController.text.trim().toLowerCase();
    final countries = widget.countries.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.dialCode.contains(query);
    }).toList();

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: const Color(0xFF0D172D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 74,
            child: TextField(
              controller: widget.searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 22),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 22),
                hintText: 'Search country...',
                hintStyle: TextStyle(color: Colors.white60, fontSize: 22),
              ),
            ),
          ),
          const Divider(height: 1, color: Colors.white24),
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: countries.length,
              itemBuilder: (context, index) {
                final country = countries[index];
                final isSelected =
                    country.name == widget.selectedCountry.name &&
                        country.dialCode == widget.selectedCountry.dialCode;

                return InkWell(
                  onTap: () => widget.onSelected(country),
                  child: Container(
                    height: 92,
                    color: isSelected
                        ? const Color(0xFF3F6FFF)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Text(
                          country.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 22),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                country.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Dial code ${country.dialCode}',
                                style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          country.dialCode,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryCode {
  final String name;
  final String dialCode;
  final String flag;

  const _CountryCode(this.name, this.dialCode, this.flag);
}
