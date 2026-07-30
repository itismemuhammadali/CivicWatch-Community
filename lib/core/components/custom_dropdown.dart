import 'package:cctv_app/core/theme/app_colors.dart';
import 'package:cctv_app/core/utils/color_constants.dart';
import 'package:cctv_app/core/utils/validators.dart';
import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatefulWidget {
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final String hint;
  final double screenWidth;
  final bool isSmallScreen;
  final ValueChanged<T?>? onChanged;
  final Color? borderColor;
  final Color? fillColor;
  final Color? dropdownColor;
  final bool isSearchable;
  final bool openSearchInPopup;
  final bool enabled;
  final String? searchHintText;
  final String Function(T value)? itemLabelBuilder;
  final FormFieldValidator<T>? validator;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.hint,
    required this.screenWidth,
    required this.isSmallScreen,
    this.onChanged,
    this.borderColor,
    this.fillColor,
    this.dropdownColor,
    this.isSearchable = false,
    this.openSearchInPopup = false,
    this.enabled = true,
    this.searchHintText,
    this.itemLabelBuilder,
    this.validator,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T> extends State<CustomDropdown<T>> {
  late final TextEditingController _searchController;
  late final TextEditingController _popupSearchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: _labelForValue(widget.value),
    );
    _popupSearchController = TextEditingController();
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _searchController.text = _labelForValue(widget.value);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _popupSearchController.dispose();
    super.dispose();
  }

  Future<void> _openSelectionPopup(
    BuildContext context,
    FormFieldState<T> field,
    Color effectiveBorderColor,
    Color effectiveFillColor,
  ) async {
    _popupSearchController.clear();

    final result = await showDialog<T>(
      context: context,
      builder: (dialogContext) {
        String query = '';

        return StatefulBuilder(
          builder: (context, setPopupState) {
            final filteredItems = widget.items.where((item) {
              if (item.value == null) return false;
              final label = _labelForValue(item.value).toLowerCase();
              return label.contains(query.toLowerCase().trim());
            }).toList();

            return AlertDialog(
              backgroundColor: widget.dropdownColor ?? kWhiteColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: Text(
                widget.hint,
                style: TextStyle(color: AppColors.blackColor),
              ),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _popupSearchController,
                      autofocus: true,
                      onChanged: (value) {
                        setPopupState(() {
                          query = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: widget.searchHintText ?? widget.hint,
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: effectiveFillColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: effectiveBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: effectiveBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide(color: effectiveBorderColor),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 320),
                        child: filteredItems.isEmpty
                            ? Center(
                                child: Text(
                                  'No results found',
                                  style: TextStyle(
                                    color: AppColors.blackColor,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredItems.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 4),
                                itemBuilder: (context, index) {
                                  final item = filteredItems[index];
                                  final itemValue = item.value as T;
                                  final isSelected = field.value == itemValue;

                                  return Material(
                                    color: isSelected
                                        ? kPrimaryColor.withValues(alpha: 0.08)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                    child: ListTile(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      title: Text(
                                        _labelForValue(itemValue),
                                        style: TextStyle(
                                          color: AppColors.blackColor,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(Icons.check)
                                          : null,
                                      onTap: () {
                                        Navigator.of(dialogContext).pop(
                                          itemValue,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == null) return;

    field.didChange(result);
    _searchController.text = _labelForValue(result);
    widget.onChanged?.call(result);
  }

  String _labelForValue(T? value) {
    if (value == null) return '';
    if (widget.itemLabelBuilder != null) {
      return widget.itemLabelBuilder!(value);
    }

    final matchedItem = widget.items.cast<DropdownMenuItem<T>?>().firstWhere(
      (item) => item?.value == value,
      orElse: () => null,
    );

    final child = matchedItem?.child;
    if (child is Text && child.data != null) {
      return child.data!;
    }

    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = widget.borderColor ?? kGreyColor;
    final effectiveFillColor = widget.fillColor ?? kWhiteColor;
    final effectiveDropdownColor = widget.dropdownColor ?? kWhiteColor;
    final validator =
        widget.validator ?? (value) => Validators.required(value?.toString());

    if (!widget.isSearchable) {
      return DropdownButtonFormField<T>(
        initialValue: widget.value,
        items: widget.items,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onChanged: widget.enabled ? widget.onChanged : null,
        decoration: InputDecoration(
          hintText: widget.hint,
          filled: true,
          fillColor: effectiveFillColor,
          contentPadding: EdgeInsets.symmetric(
            horizontal: widget.screenWidth * 0.04,
            vertical: widget.screenWidth * 0.02,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(13),
            borderSide: BorderSide(color: effectiveBorderColor),
          ),
        ),
        style: TextStyle(
          fontSize: widget.screenWidth * 0.04,
          fontWeight: FontWeight.bold,
          color: AppColors.blackColor,
        ),
        dropdownColor: effectiveDropdownColor,
      );
    }

    return FormField<T>(
      initialValue: widget.value,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (field) {
        if (widget.openSearchInPopup) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(13),
                onTap: widget.enabled
                    ? () => _openSelectionPopup(
                        context,
                        field,
                        effectiveBorderColor,
                        effectiveFillColor,
                      )
                    : null,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: widget.hint,
                    labelStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kDarkGreyColor,
                    ),
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: kBlackColor,
                    ),
                    floatingLabelBehavior: FloatingLabelBehavior.never,
                    isDense: true,
                    filled: true,
                    fillColor: widget.enabled
                        ? effectiveFillColor
                        : effectiveFillColor.withValues(alpha: 0.7),
                    contentPadding: EdgeInsets.only(
                      left: widget.screenWidth * 0.04,
                      right: 0,
                      top: 16,
                      bottom: 16,
                    ),
                    constraints: const BoxConstraints(minHeight: 52),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                    errorText: field.hasError ? '' : null,
                    suffixIcon: Icon(
                      Icons.arrow_drop_down,
                      color: widget.enabled ? null : Colors.grey,
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      minWidth: 40,
                      minHeight: 40,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      field.value == null
                          ? ''
                          : _labelForValue(field.value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: widget.screenWidth * 0.04,
                        fontWeight: FontWeight.bold,
                        color: !widget.enabled
                            ? Colors.grey
                            : field.value == null
                            ? Colors.grey
                            : AppColors.blackColor,
                      ),
                    ),
                  ),
                ),
              ),
              if (field.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 6, right: 12),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      field.errorText ?? '',
                      style: const TextStyle(color: kRedColor, fontSize: 12),
                    ),
                  ),
                ),
            ],
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownMenu<T>(
                  initialSelection: field.value,
                  controller: _searchController,
                  hintText: widget.searchHintText ?? widget.hint,
                  enableSearch: true,
                  enableFilter: true,
                  enabled: widget.enabled,
                  width: constraints.maxWidth,
                  requestFocusOnTap: true,
                  inputDecorationTheme: InputDecorationTheme(
                    filled: true,
                    fillColor: effectiveFillColor,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: widget.screenWidth * 0.04,
                      vertical: widget.screenWidth * 0.02,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(13),
                      borderSide: BorderSide(color: effectiveBorderColor),
                    ),
                  ),
                  textStyle: TextStyle(
                    fontSize: widget.screenWidth * 0.04,
                    fontWeight: FontWeight.bold,
                    color: AppColors.blackColor,
                  ),
                  menuStyle: MenuStyle(
                    backgroundColor: WidgetStatePropertyAll(
                      effectiveDropdownColor,
                    ),
                  ),
                  searchCallback: (entries, query) {
                    final normalizedQuery = query.toLowerCase().trim();
                    if (normalizedQuery.isEmpty) return null;

                    for (var index = 0; index < entries.length; index++) {
                      if (entries[index].label.toLowerCase().contains(
                        normalizedQuery,
                      )) {
                        return index;
                      }
                    }
                    return null;
                  },
                  dropdownMenuEntries: widget.items
                      .where((item) => item.value != null)
                      .map(
                        (item) => DropdownMenuEntry<T>(
                          value: item.value as T,
                          label: _labelForValue(item.value),
                        ),
                      )
                      .toList(),
                  onSelected: (value) {
                    field.didChange(value);
                    widget.onChanged?.call(value);
                  },
                ),
                if (field.hasError)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 12),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        field.errorText ?? '',
                        style: TextStyle(color: kRedColor, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
