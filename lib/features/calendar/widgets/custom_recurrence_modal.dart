import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:birthday_calendar/features/calendar/models/custom_recurrence.dart';
import 'package:birthday_calendar/shared/widgets/base_modal.dart';

class CustomRecurrenceModal extends StatefulWidget {
  final DateTime startDate;
  final CustomRecurrence? initialRecurrence;

  const CustomRecurrenceModal({
    super.key,
    required this.startDate,
    this.initialRecurrence,
  });

  @override
  State<CustomRecurrenceModal> createState() => _CustomRecurrenceModalState();
}

class _CustomRecurrenceModalState extends State<CustomRecurrenceModal> {
  late int _interval;
  late CustomRecurrenceUnit _unit;
  List<int> _daysOfWeek = [];
  bool _isWeekday = false;
  CustomMonthType _monthType = CustomMonthType.dayOfMonth;
  CustomEndType _endType = CustomEndType.none;
  DateTime? _endDate;
  int? _count;

  final TextEditingController _intervalController = TextEditingController();
  final TextEditingController _countController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialRecurrence != null) {
      final r = widget.initialRecurrence!;
      _interval = r.interval;
      _unit = r.unit;
      if (r.daysOfWeek != null) _daysOfWeek = List.from(r.daysOfWeek!);
      _isWeekday = r.isWeekday;
      _monthType = r.monthType ?? CustomMonthType.dayOfMonth;
      _endType = r.endType;
      _endDate = r.endDate ?? widget.startDate;
      _count = r.count;
    } else {
      _interval = 1;
      _unit = CustomRecurrenceUnit.weeks;
      _daysOfWeek = [widget.startDate.weekday]; // デフォルトは開始日の曜日
      _endDate = widget.startDate;
      _count = 10;
    }

    _intervalController.text = _interval.toString();
    if (_count != null) {
      _countController.text = _count.toString();
    }
    
    // 値が変わったら再描画して上部の文字を更新する
    _intervalController.addListener(() {
      final val = int.tryParse(_intervalController.text);
      if (val != null && val > 0) {
        setState(() {
          _interval = val;
        });
      }
    });
    _countController.addListener(() {
      final val = int.tryParse(_countController.text);
      if (val != null && val > 0) {
        setState(() {
          _count = val;
        });
      }
    });
  }

  @override
  void dispose() {
    _intervalController.dispose();
    _countController.dispose();
    super.dispose();
  }

  CustomRecurrence _buildCurrentRecurrence() {
    return CustomRecurrence(
      interval: _interval,
      unit: _unit,
      daysOfWeek: _unit == CustomRecurrenceUnit.weeks ? _daysOfWeek : null,
      isWeekday: _unit == CustomRecurrenceUnit.weeks ? _isWeekday : false,
      monthType: _unit == CustomRecurrenceUnit.months ? _monthType : null,
      endType: _endType,
      endDate: _endType == CustomEndType.date ? _endDate : null,
      count: _endType == CustomEndType.count ? _count : null,
    );
  }

  void _onSave() {
    Navigator.of(context).pop(_buildCurrentRecurrence());
  }

  // 第○X曜日 を計算するヘルパー
  int _getWeekNumber(DateTime date) {
    return ((date.day - 1) ~/ 7) + 1;
  }
  
  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1: return '月';
      case 2: return '火';
      case 3: return '水';
      case 4: return '木';
      case 5: return '金';
      case 6: return '土';
      case 7: return '日';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCustom = _buildCurrentRecurrence();
    final theme = Theme.of(context);

    // 曜日選択のUI
    final daysOfWeekMap = {
      7: '日', 1: '月', 2: '火', 3: '水', 4: '木', 5: '金', 6: '土'
    };

    return BaseModal(
      title: '繰り返しカスタム',
      leadingIcon: Icons.arrow_back,
      isEditMode: true, // 保存ボタンのみ表示するため
      onSave: _onSave,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 上部のカスタム設定表示
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentCustom.toReadableString(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),

            // 繰り返す間隔
            const Text('繰り返す間隔', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: _intervalController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<CustomRecurrenceUnit>(
                    value: _unit,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: CustomRecurrenceUnit.days, child: Text('日')),
                      DropdownMenuItem(value: CustomRecurrenceUnit.weeks, child: Text('週間')),
                      DropdownMenuItem(value: CustomRecurrenceUnit.months, child: Text('か月')),
                      DropdownMenuItem(value: CustomRecurrenceUnit.years, child: Text('年')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _unit = val;
                          if (_unit == CustomRecurrenceUnit.weeks && _daysOfWeek.isEmpty) {
                            _daysOfWeek = [widget.startDate.weekday];
                          }
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // 単位ごとの詳細設定
            if (_unit == CustomRecurrenceUnit.weeks) ...[
              const Text('曜日', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: daysOfWeekMap.entries.map((entry) {
                  final isSelected = _daysOfWeek.contains(entry.key);
                  return GestureDetector(
                    onTap: _isWeekday ? null : () {
                      setState(() {
                        if (isSelected && _daysOfWeek.length > 1) {
                          _daysOfWeek.remove(entry.key);
                        } else if (!isSelected) {
                          _daysOfWeek.add(entry.key);
                        }
                      });
                    },
                    child: Opacity(
                      opacity: _isWeekday ? 0.4 : 1.0,
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? theme.colorScheme.primary : Colors.grey.shade300,
                        ),
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? theme.colorScheme.onPrimary : Colors.grey.shade800,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('平日 (祝日を除く)'),
                value: _isWeekday,
                onChanged: (val) {
                  setState(() {
                    _isWeekday = val;
                  });
                },
              ),
            ] else if (_unit == CustomRecurrenceUnit.months) ...[
              const Text('月の繰り返し方法', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<CustomMonthType>(
                value: _monthType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(
                    value: CustomMonthType.dayOfMonth, 
                    child: Text('毎月 ${widget.startDate.day} 日')
                  ),
                  DropdownMenuItem(
                    value: CustomMonthType.nthWeekday, 
                    child: Text('第${_getWeekNumber(widget.startDate)}${_getWeekdayName(widget.startDate.weekday)}曜日')
                  ),
                ],
                onChanged: (val) {
                  if (val != null) setState(() { _monthType = val; });
                },
              ),
            ],

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // 終了設定
            const Text('終了設定', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Column(
              children: [
                RadioListTile<CustomEndType>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('期限なし'),
                  value: CustomEndType.none,
                  groupValue: _endType,
                  onChanged: (val) => setState(() => _endType = val!),
                ),
                // ignore: deprecated_member_use
                RadioListTile<CustomEndType>(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('日付指定'),
                      const Spacer(),
                      if (_endType == CustomEndType.date)
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _endDate ?? widget.startDate,
                              firstDate: widget.startDate,
                              lastDate: DateTime(2100),
                            );
                            if (date != null) {
                              setState(() {
                                _endDate = date;
                              });
                            }
                          },
                          child: Text(
                            _endDate != null ? DateFormat('yyyy年M月d日').format(_endDate!) : '日付を選択',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                    ],
                  ),
                  value: CustomEndType.date,
                  groupValue: _endType,
                  onChanged: (val) => setState(() => _endType = val!),
                ),
                // ignore: deprecated_member_use
                RadioListTile<CustomEndType>(
                  contentPadding: EdgeInsets.zero,
                  title: Row(
                    children: [
                      const Text('回数指定'),
                      const Spacer(),
                      if (_endType == CustomEndType.count)
                        SizedBox(
                          width: 80,
                          child: TextField(
                            controller: _countController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                              suffixText: '回',
                            ),
                          ),
                        ),
                    ],
                  ),
                  value: CustomEndType.count,
                  groupValue: _endType,
                  onChanged: (val) => setState(() => _endType = val!),
                ),
              ],
            ),
            
            const SizedBox(height: 48), // スクロール余白
          ],
        ),
      ),
    );
  }
}
