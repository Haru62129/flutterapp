import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(const MoodDiaryApp());
}

class MoodDiaryApp extends StatelessWidget {
  const MoodDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'きぶん日記',
      theme: ThemeData(
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFFFFF9F0),
        primarySwatch: Colors.orange,
      ),
      home: const MoodHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MoodHomePage extends StatefulWidget {
  const MoodHomePage({super.key});

  @override
  State<MoodHomePage> createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage> with SingleTickerProviderStateMixin {
  String? selectedMood;
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic> moodLog = {};
  bool hasRecordedToday = false;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  File? _selectedImage;
  String? selectedMoodFilter;

  late AnimationController _msgController;
  late Animation<double> _msgAnimation;

  final Map<String, List<String>> moodMessages = {
    'excited': ['最高の気分！', '今日も全力だ！', 'ワクワクが止まらない！'],
    'happy': ['いい日だね！', 'ニコニコ笑顔で！', 'ハッピーを感じてる？'],
    'neutral': ['穏やかな一日を', 'まあまあだね', '今日もぼちぼち'],
    'sad': ['大丈夫、明日はきっと', 'ゆっくり休んでね', '辛い時もあるよね'],
    'angry': ['深呼吸しよう', '気持ちを落ち着けて', 'イライラはバイバイ！'],
    'tired': ['よく頑張ったね', 'ゆっくり休んでね', '疲れは溜めすぎないで'],
  };

  final Map<String, String> moodEmojiMap = {
    'excited': '🤩',
    'happy': '😄',
    'neutral': '😐',
    'sad': '😢',
    'angry': '😡',
    'tired': '😴',
  };

  @override
  void initState() {
    super.initState();
    _loadMoodLog();

    _msgController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _msgAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _msgController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _msgController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadMoodLog() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('moodLog');
    if (jsonString != null) {
      final decoded = jsonDecode(jsonString);
      setState(() {
        moodLog = Map<String, dynamic>.from(decoded);
        final today = DateTime.now().toIso8601String().split('T')[0];
        hasRecordedToday = moodLog.containsKey(today);
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(picked.path);
      final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');
      setState(() {
        _selectedImage = savedImage;
      });
    }
  }

  Future<void> saveTodayMood() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (selectedMood == null || hasRecordedToday) return;

    setState(() {
      moodLog[today] = {
        'mood': selectedMood,
        'note': _noteController.text,
        'imagePath': _selectedImage?.path,
      };
      _noteController.clear();
      selectedMood = null;
      _selectedImage = null;
      hasRecordedToday = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(moodLog);
    await prefs.setString('moodLog', jsonString);

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('気分を記録しました')),
    );

    _showMessagePopup(moodLog[today]!['mood']);
  }

  void _showMessagePopup(String mood) {
    final messages = moodMessages[mood] ?? ['今日もがんばろう！'];
    final randomMsg = (messages..shuffle()).first;

    _msgController.reset();
    _msgController.forward();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => Center(
        child: ScaleTransition(
          scale: _msgAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: 280,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    moodEmojiMap[mood] ?? '🙂',
                    style: const TextStyle(fontSize: 64),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    randomMsg,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK', style: TextStyle(fontSize: 18)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildMoodButton(String emoji, String mood) {
    final isSelected = selectedMood == mood;
    return GestureDetector(
      onTap: hasRecordedToday ? null : () => setState(() => selectedMood = mood),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange[100] : Colors.orange[50],
          shape: BoxShape.circle,
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.orange.shade200, blurRadius: 10, spreadRadius: 1)]
              : [],
        ),
        child: isSelected
            ? ScaleTransition(
                scale: Tween<double>(begin: 1.0, end: 1.3)
                    .animate(CurvedAnimation(parent: _msgController, curve: Curves.easeInOut)),
                child: Text(emoji, style: const TextStyle(fontSize: 32)),
              )
            : Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  String formatWeekLabel(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDay.weekday % 7;
    final weekNumber = ((date.day + firstWeekday - 1) / 7).floor() + 1;
    return '${date.month}月第$weekNumber週';
  }

  Map<String, int> _generateMoodFrequencyByWeek() {
    final result = <String, Map<String, int>>{};

    moodLog.forEach((dateStr, entry) {
      final date = DateTime.parse(dateStr);
      if (date.year == selectedYear && date.month == selectedMonth) {
        final weekLabel = formatWeekLabel(date);
        final mood = entry['mood'];
        result.putIfAbsent(weekLabel, () => {
          'excited': 0,
          'happy': 0,
          'neutral': 0,
          'sad': 0,
          'angry': 0,
          'tired': 0,
        });
        result[weekLabel]![mood] = result[weekLabel]![mood]! + 1;
      }
    });

    final moodCounts = <String, int>{
      'excited': 0,
      'happy': 0,
      'neutral': 0,
      'sad': 0,
      'angry': 0,
      'tired': 0,
    };

    result.forEach((week, moods) {
      moods.forEach((mood, count) {
        moodCounts[mood] = moodCounts[mood]! + count;
      });
    });

    return moodCounts;
  }

  List<MapEntry<String, dynamic>> _getFilteredMoodLog() {
    final filteredEntries = moodLog.entries.where((entry) {
      final date = DateTime.parse(entry.key);
      final matchesDate = date.year == selectedYear && date.month == selectedMonth;
      final matchesMood = selectedMoodFilter == null || entry.value['mood'] == selectedMoodFilter;
      return matchesDate && matchesMood;
    }).toList();

    filteredEntries.sort((a, b) => b.key.compareTo(a.key));
    return filteredEntries;
  }

  String _getMoodJapaneseName(String mood) {
    const moodNames = {
      'excited': 'とても嬉しい',
      'happy': '嬉しい',
      'neutral': '普通',
      'sad': '悲しい',
      'angry': '怒り',
      'tired': '疲れ',
    };
    return moodNames[mood] ?? mood;
  }

  void _showEditMemoDialog(String dateKey, Map<String, dynamic> moodData) async {
    String? editMood = moodData['mood'];
    final TextEditingController editNoteController = TextEditingController(text: moodData['note']);
    File? editImage = moodData['imagePath'] != null ? File(moodData['imagePath']) : null;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('${DateFormat('M月d日', 'ja').format(DateTime.parse(dateKey))}の記録を編集'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Wrap(
                  children: moodEmojiMap.entries.map((e) => GestureDetector(
                    onTap: () => setDialogState(() => editMood = e.key),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: CircleAvatar(
                        backgroundColor: editMood == e.key ? Colors.orange : Colors.grey.shade200,
                        child: Text(e.value, style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: editNoteController,
                  decoration: const InputDecoration(labelText: 'メモ'),
                  maxLines: 3,
                ),
                if (editImage != null && editImage!.existsSync())
                 Padding(
                   padding: const EdgeInsets.only(top: 8),
                   child: Image.file(editImage!, width: 80, height: 80),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text('画像変更'),
                  onPressed: () async {
                    final picker = ImagePicker();
                    final picked = await picker.pickImage(source: ImageSource.gallery);
                    if (picked != null) {
                      final appDir = await getApplicationDocumentsDirectory();
                      final fileName = path.basename(picked.path);
                      final savedImage = await File(picked.path).copy('${appDir.path}/$fileName');
                      setDialogState(() {
                        editImage = savedImage;
                      });
                    }
                  },
                ),
                if (editImage != null)
                  TextButton.icon(
                    icon: const Icon(Icons.delete),
                    label: const Text('画像削除'),
                    onPressed: () {
                      setDialogState(() {
                        editImage = null;
                      });
                    },
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text('保存'),
              onPressed: () async {
                setState(() {
                  moodLog[dateKey] = {
                    'mood': editMood,
                    'note': editNoteController.text,
                    'imagePath': editImage?.path,
                  };
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('moodLog', jsonEncode(moodLog));
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: const Text('削除'),
              onPressed: () async {
                setState(() {
                  moodLog.remove(dateKey);
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('moodLog', jsonEncode(moodLog));
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemoList() {
    final filteredEntries = _getFilteredMoodLog();

    if (filteredEntries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'メモがありません',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ),
      );
    }

    return Column(
      children: filteredEntries.map((entry) {
        final date = DateTime.parse(entry.key);
        final moodData = entry.value;
        final mood = moodData['mood'] as String;
        final note = moodData['note'] as String? ?? '';
        final imagePath = moodData['imagePath'] as String?;

        return GestureDetector(
          onTap: () => _showEditMemoDialog(entry.key, moodData),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      DateFormat('M月d日(E)', 'ja').format(date),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${moodEmojiMap[mood]} ${_getMoodJapaneseName(mood)}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                if (note.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    note,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
                if (imagePath != null && File(imagePath).existsSync()) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(imagePath),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final weeks = <String>[];
    final now = DateTime.now();
    final daysInMonth = DateTime(selectedYear, selectedMonth + 1, 0).day;

    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(selectedYear, selectedMonth, d);
      final weekLabel = formatWeekLabel(date);
      if (!weeks.contains(weekLabel)) weeks.add(weekLabel);
    }

    final moodFrequency = _generateMoodFrequencyByWeek();

    return Scaffold(
      appBar: AppBar(
        title: const Text('きぶん日記'),
        centerTitle: true,
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<int>(
                    value: selectedYear,
                    items: List.generate(now.year - 2000 + 1, (index) {
                      final year = 2000 + index;
                      return DropdownMenuItem(
                        value: year,
                        child: Text('$year年'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedYear = val;
                          hasRecordedToday = false;
                          selectedMoodFilter = null;
                          _loadMoodLog();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: List.generate(12, (index) {
                      final month = index + 1;
                      return DropdownMenuItem(
                        value: month,
                        child: Text('$month月'),
                      );
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          selectedMonth = val;
                          hasRecordedToday = false;
                          selectedMoodFilter = null;
                          _loadMoodLog();
                        });
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('気分フィルター:'),
                  ...moodEmojiMap.entries.map((e) => GestureDetector(
                    onTap: () => setState(() {
                      selectedMoodFilter = selectedMoodFilter == e.key ? null : e.key;
                    }),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedMoodFilter == e.key ? Colors.orange[100] : Colors.grey.shade200,
                        shape: BoxShape.circle,
                      ),
                      child: Text(e.value, style: const TextStyle(fontSize: 24)),
                    ),
                  )),
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => selectedMoodFilter = null),
                    tooltip: 'フィルター解除',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (!hasRecordedToday) ...[
                const Text('今日の気分を選んでください', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  children: moodEmojiMap.entries
                      .map((e) => buildMoodButton(e.value, e.key))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'メモ（任意）',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.image),
                      label: const Text('画像選択'),
                      onPressed: _pickImage,
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: selectedMood == null ? null : saveTodayMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('記録する', style: TextStyle(fontSize: 18)),
                    ),
                  ],
                ),
                if (_selectedImage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Image.file(_selectedImage!, width: 120, height: 120, fit: BoxFit.cover),
                  ),
              ] else ...[
                const Text('本日はすでに記録済みです', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'メモ一覧（タップで編集）',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange.shade700),
                ),
              ),
              const SizedBox(height: 8),
              _buildMemoList(),
              const SizedBox(height: 24),
              SizedBox(
                height: 300,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() < 0 || value.toInt() >= moodEmojiMap.length) {
                              return const SizedBox.shrink();
                            }
                            final mood = moodEmojiMap.entries.elementAt(value.toInt());
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    mood.value,
                                    style: const TextStyle(fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    mood.key,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 2,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            if (value % 2 != 0) return const SizedBox.shrink();
                            return Text(value.toInt().toString());
                          },
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    barGroups: List.generate(moodEmojiMap.length, (index) {
                      final mood = moodEmojiMap.entries.elementAt(index).key;
                      final count = moodFrequency[mood]?.toDouble() ?? 0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: count,
                            width: 25,
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          )
                        ],
                      );
                    }),
                    gridData: FlGridData(show: true),
                    borderData: FlBorderData(show: false),
                    groupsSpace: 36,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}