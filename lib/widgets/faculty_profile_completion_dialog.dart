import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';

class FacultyProfileCompletionDialog extends ConsumerStatefulWidget {
  const FacultyProfileCompletionDialog({super.key});

  @override
  ConsumerState<FacultyProfileCompletionDialog> createState() =>
      _FacultyProfileCompletionDialogState();
}

class _ReferenceOption {
  final int id;
  final String label;

  const _ReferenceOption({
    required this.id,
    required this.label,
  });
}

class _FacultyProfileCompletionDialogState
    extends ConsumerState<FacultyProfileCompletionDialog> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _middleNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingColleges = true;
  bool _isLoadingDepartments = false;

  List<_ReferenceOption> _colleges = const [];
  List<_ReferenceOption> _departments = const [];

  int? _selectedCollegeId;
  int? _selectedDepartmentId;
  String? _selectedPosition;

  static const String _positionPlaceholder = '-- Select Position --';
  static const Color _dropdownValueColor = Color(0xFF111827);
  static const Color _dropdownHintColor = Color(0xFF667085);
  static const List<String> _positionOptions = [
    'Full-time',
    'Part-time',
    'Regular',
    'Contractual',
    'Visiting',
    'Temporary',
  ];

  @override
  void initState() {
    super.initState();
    _prefillFromCurrentUser();
    _loadColleges();
  }

  TextStyle _dropdownValueStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return baseStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: _dropdownValueColor,
    );
  }

  TextStyle _dropdownHintStyle(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodyMedium ??
        const TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return baseStyle.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: _dropdownHintColor,
    );
  }

  Widget _buildDropdownText(
    BuildContext context,
    String value, {
    bool isHint = false,
  }) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          isHint ? _dropdownHintStyle(context) : _dropdownValueStyle(context),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _prefillFromCurrentUser() {
    final user = ref.read(authProvider).user;
    if (user == null) {
      _selectedPosition = null;
      return;
    }

    _firstNameController.text = user.firstName ?? '';
    _middleNameController.text = user.middleName ?? '';
    _lastNameController.text = user.lastName ?? '';
    _addressController.text = user.address ?? '';

    _selectedCollegeId = user.college?.id;
    _selectedDepartmentId = user.department?.id;

    final position = user.position?.trim();
    if (position == null || position.isEmpty) {
      _selectedPosition = null;
      return;
    }

    _selectedPosition = _positionOptions.contains(position) ? position : null;
  }

  int? _toInt(dynamic candidate) {
    if (candidate is int) {
      return candidate;
    }

    if (candidate is String) {
      final trimmed = candidate.trim();
      final direct = int.tryParse(trimmed);
      if (direct != null) {
        return direct;
      }

      // API Platform commonly returns IRI values like /api/colleges/3.
      final iriMatch = RegExp(r'(\d+)$').firstMatch(trimmed);
      if (iriMatch != null) {
        return int.tryParse(iriMatch.group(1)!);
      }
    }

    return null;
  }

  int? _parseOptionId(Map<String, dynamic> item) {
    final candidates = [
      item['id'],
      item['value'],
      item['college_id'],
      item['department_id'],
      item['collegeId'],
      item['departmentId'],
      item['collegeID'],
      item['departmentID'],
      item['@id'],
      item['iri'],
      item['college'] is Map ? (item['college'] as Map)['id'] : null,
      item['department'] is Map ? (item['department'] as Map)['id'] : null,
      item['college'] is Map ? (item['college'] as Map)['@id'] : null,
      item['department'] is Map ? (item['department'] as Map)['@id'] : null,
    ];

    for (final candidate in candidates) {
      final parsed = _toInt(candidate);
      if (parsed != null) {
        return parsed;
      }
    }

    return null;
  }

  String _parseOptionLabel(Map<String, dynamic> item, int id) {
    final candidates = [
      item['name'],
      item['label'],
      item['title'],
      item['display_name'],
      item['code'],
      item['college_name'],
      item['department_name'],
      item['collegeName'],
      item['departmentName'],
      item['college'] is Map ? (item['college'] as Map)['name'] : null,
      item['department'] is Map ? (item['department'] as Map)['name'] : null,
    ];

    for (final candidate in candidates) {
      if (candidate is String && candidate.trim().isNotEmpty) {
        return candidate.trim();
      }
    }

    return 'Option $id';
  }

  List<_ReferenceOption> _toOptions(List<Map<String, dynamic>> raw) {
    final seen = <int>{};
    final options = <_ReferenceOption>[];

    for (final item in raw) {
      final id = _parseOptionId(item);
      if (id == null || seen.contains(id)) {
        continue;
      }
      seen.add(id);
      options.add(_ReferenceOption(id: id, label: _parseOptionLabel(item, id)));
    }

    return options;
  }

  bool _isDepartmentUnderCollege(Map<String, dynamic> item, int collegeId) {
    final candidates = [
      item['college_id'],
      item['collegeId'],
      item['collegeID'],
      item['college'] is Map ? (item['college'] as Map)['id'] : null,
    ];

    for (final candidate in candidates) {
      final parsed = _toInt(candidate);
      if (parsed != null) {
        return parsed == collegeId;
      }
    }

    return false;
  }

  List<Map<String, dynamic>> _filterDepartmentsByCollege(
    List<Map<String, dynamic>> rows,
    int? collegeId,
  ) {
    if (collegeId == null) {
      return const [];
    }

    final filtered = rows
        .where((item) => _isDepartmentUnderCollege(item, collegeId))
        .toList();

    // If backend already filtered response and does not include a college key,
    // keep the original list.
    if (filtered.isEmpty) {
      return rows;
    }

    return filtered;
  }

  Future<void> _loadColleges() async {
    setState(() {
      _isLoadingColleges = true;
    });

    try {
      final rawColleges = await ref.read(apiServiceProvider).getColleges();
      final colleges = _toOptions(rawColleges);

      if (!mounted) {
        return;
      }

      setState(() {
        _colleges = colleges;

        if (_colleges.isEmpty) {
          _selectedCollegeId = null;
        } else if (_selectedCollegeId != null &&
            !_colleges.any((item) => item.id == _selectedCollegeId)) {
          _selectedCollegeId = null;
        }

        _selectedDepartmentId = null;
        _departments = const [];
      });

      if (_selectedCollegeId != null) {
        await _loadDepartments();
      }
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _colleges = const [];
        _departments = const [];
        _selectedCollegeId = null;
        _selectedDepartmentId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingColleges = false;
        });
      }
    }
  }

  Future<void> _loadDepartments() async {
    if (_selectedCollegeId == null) {
      setState(() {
        _departments = const [];
        _selectedDepartmentId = null;
      });
      return;
    }

    setState(() {
      _isLoadingDepartments = true;
    });

    try {
      final rawDepartments = await ref.read(apiServiceProvider).getDepartments(
            collegeId: _selectedCollegeId,
          );
      final filteredRaw =
          _filterDepartmentsByCollege(rawDepartments, _selectedCollegeId);
      final departments = _toOptions(filteredRaw);

      if (!mounted) {
        return;
      }

      setState(() {
        _departments = departments;

        if (_departments.isEmpty) {
          _selectedDepartmentId = null;
        } else if (_selectedDepartmentId != null &&
            !_departments.any((item) => item.id == _selectedDepartmentId)) {
          _selectedDepartmentId = null;
        }
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _departments = const [];
        _selectedDepartmentId = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingDepartments = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) {
      return;
    }

    final collegeId = _selectedCollegeId;
    final departmentId = _selectedDepartmentId;

    if (collegeId == null || departmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both college and department.'),
          backgroundColor: Color(0xFFB42318),
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final payload = <String, dynamic>{
      'first_name': _firstNameController.text.trim(),
      'middle_name': _middleNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'address': _addressController.text.trim(),
      'position': _selectedPosition,
      'college_id': collegeId,
      'department_id': departmentId,
    };

    payload.removeWhere((key, value) {
      if (value == null) {
        return true;
      }
      if (value is String) {
        return value.trim().isEmpty;
      }
      return false;
    });

    await ref.read(authProvider.notifier).completeProfile(payload);

    if (!mounted) {
      return;
    }

    final updatedAuthState = ref.read(authProvider);
    final error = updatedAuthState.error;
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: const Color(0xFFB42318),
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
      return;
    }

    final updatedUser = updatedAuthState.user;
    if (updatedUser != null && updatedUser.profileComplete) {
      Navigator.of(context).pop();
      return;
    }

    setState(() {
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Profile was saved but is still incomplete. Please fill all required fields.',
        ),
        backgroundColor: Color(0xFFB42318),
      ),
    );
  }

  Widget _buildNameFields() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 560) {
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'First Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _middleNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Middle Name'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Required'
                      : null,
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            TextFormField(
              controller: _firstNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'First Name'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _middleNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Middle Name'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lastNameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Last Name'),
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Required' : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildCollegeField() {
    if (_isLoadingColleges) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_colleges.isEmpty) {
      return DropdownButtonFormField<int>(
        initialValue: null,
        isExpanded: true,
        style: _dropdownValueStyle(context),
        decoration: const InputDecoration(labelText: 'College'),
        items: [
          DropdownMenuItem<int>(
            child: _buildDropdownText(
              context,
              'No colleges available',
              isHint: true,
            ),
          ),
        ],
        onChanged: null,
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedCollegeId,
      isExpanded: true,
      style: _dropdownValueStyle(context),
      hint: _buildDropdownText(context, 'Select a college', isHint: true),
      decoration: const InputDecoration(labelText: 'College'),
      items: _colleges
          .map(
            (college) => DropdownMenuItem<int>(
              value: college.id,
              child: _buildDropdownText(context, college.label),
            ),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) async {
              setState(() {
                _selectedCollegeId = value;
                _selectedDepartmentId = null;
              });
              await _loadDepartments();
            },
      validator: (value) => value == null ? 'Please select a college.' : null,
    );
  }

  Widget _buildDepartmentField() {
    if (_selectedCollegeId == null) {
      return DropdownButtonFormField<int>(
        initialValue: null,
        isExpanded: true,
        style: _dropdownValueStyle(context),
        decoration: const InputDecoration(labelText: 'Department'),
        items: [
          DropdownMenuItem<int>(
            child: _buildDropdownText(
              context,
              'Select a college first',
              isHint: true,
            ),
          ),
        ],
        onChanged: null,
      );
    }

    if (_isLoadingDepartments) {
      return const LinearProgressIndicator(minHeight: 2);
    }

    if (_departments.isEmpty) {
      return DropdownButtonFormField<int>(
        initialValue: null,
        isExpanded: true,
        style: _dropdownValueStyle(context),
        decoration: const InputDecoration(labelText: 'Department'),
        items: [
          DropdownMenuItem<int>(
            child: _buildDropdownText(
              context,
              'No departments available for selected college',
              isHint: true,
            ),
          ),
        ],
        onChanged: null,
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedDepartmentId,
      isExpanded: true,
      style: _dropdownValueStyle(context),
      hint: _buildDropdownText(context, 'Select a department', isHint: true),
      decoration: const InputDecoration(labelText: 'Department'),
      items: _departments
          .map(
            (department) => DropdownMenuItem<int>(
              value: department.id,
              child: _buildDropdownText(context, department.label),
            ),
          )
          .toList(),
      onChanged: _isSubmitting
          ? null
          : (value) {
              setState(() {
                _selectedDepartmentId = value;
              });
            },
      validator: (value) =>
          value == null ? 'Please select a department.' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Complete Faculty Profile'),
      content: SizedBox(
        width: 640,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Please complete your profile before using the app.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 16),
                _buildNameFields(),
                const SizedBox(height: 12),
                _buildCollegeField(),
                const SizedBox(height: 12),
                _buildDepartmentField(),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _addressController,
                  minLines: 2,
                  maxLines: 3,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Address'),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Address is required.'
                      : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedPosition ?? '',
                  isExpanded: true,
                  style: _dropdownValueStyle(context),
                  decoration: const InputDecoration(labelText: 'Position'),
                  items: [
                    DropdownMenuItem<String>(
                      value: '',
                      child: _buildDropdownText(
                        context,
                        _positionPlaceholder,
                        isHint: true,
                      ),
                    ),
                    ..._positionOptions.map(
                      (position) => DropdownMenuItem<String>(
                        value: position,
                        child: _buildDropdownText(context, position),
                      ),
                    ),
                  ],
                  onChanged: _isSubmitting
                      ? null
                      : (value) {
                          setState(() {
                            _selectedPosition =
                                (value == null || value.isEmpty) ? null : value;
                          });
                        },
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Please select your position.'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSave,
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save and Continue'),
        ),
      ],
    );
  }
}
