import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const MoodDiaryApp());
}

class MoodDiaryApp extends StatelessWidget {
  const MoodDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'きぶん日記',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MoodHomePage(),
    );
  }
}

class MoodHomePage extends StatefulWidget {
  const MoodHomePage({super.key});

  @override
  State<MoodHomePage> createState() => _MoodHomePageState();
}

class _MoodHomePageState extends State<MoodHomePage> {
  String? selectedMood;
  final TextEditingController _noteController = TextEditingController();
  Map<String, dynamic> moodLog = {};
  bool hasRecordedToday = false;

  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _loadMoodLog();
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

  Future<void> saveTodayMood() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (selectedMood == null || hasRecordedToday) return;

    setState(() {
      moodLog[today] = {
        'mood': selectedMood,
        'note': _noteController.text,
      };
      _noteController.clear();
      selectedMood = null;
      hasRecordedToday = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(moodLog);
    await prefs.setString('moodLog', jsonString);

    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('気分を記録しました')),
    );
  }

  Widget buildMoodButton(String emoji, String mood) {
    return GestureDetector(
      onTap: hasRecordedToday ? null : () => setState(() => selectedMood = mood),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedMood == mood ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  String _emojiFor(String mood) {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'neutral':
        return '😐';
      case 'sad':
        return '😞';
      case 'excited':
        return '😀';
      case 'tired':
        return '😴';
      default:
        return '';
    }
  }

  String formatWeekLabel(DateTime date) {
    final month = date.month;
    final day = date.day;
    final firstDayOfMonth = DateTime(date.year, month, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7;
    final weekNumber = ((day + firstWeekday - 1) / 7).floor() + 1;
    return '${month}月第${weekNumber}週';
  }

  Map<String, int> _generateMoodFrequencyByWeek() {
    final result = <String, Map<String, int>>{};

    moodLog.forEach((dateStr, entry) {
      final date = DateTime.parse(dateStr);
      if (date.year == selectedYear && date.month == selectedMonth) {
        final weekLabel = formatWeekLabel(date);
        final mood = entry['mood'];
        result.putIfAbsent(weekLabel, () => {
              'happy': 0,
              'neutral': 0,
              'sad': 0,
              'excited': 0,
              'tired': 0,
            });
        result[weekLabel]![mood] = result[weekLabel]![mood]! + 1;
      }
    });

    final moodCounts = <String, int>{};
    for (var week in result.values) {
      week.forEach((mood, count) {
        moodCounts[mood] = (moodCounts[mood] ?? 0) + count;
      });
    }
    return moodCounts;
  }

  List<BarChartGroupData> _generateBarChart() {
    final moodCounts = _generateMoodFrequencyByWeek();
    final moods = ['sad', 'tired', 'neutral', 'happy', 'excited'];
    return List.generate(moods.length, (i) {
      final count = moodCounts[moods[i]] ?? 0;
      return BarChartGroupData(x: i, barRods: [
        BarChartRodData(toY: count.toDouble(), color: Colors.blue, width: 20),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sortedDates = moodLog.keys.toList()..sort();
    final yearList = List.generate(DateTime.now().year - 2000 + 1, (i) => 2000 + i); // 2000年から今年まで
    final monthList = List.generate(12, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('きぶん日記')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("今日の気分は？", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  buildMoodButton('😊', 'happy'),
                  buildMoodButton('😐', 'neutral'),
                  buildMoodButton('😞', 'sad'),
                  buildMoodButton('😀', 'excited'),
                  buildMoodButton('😴', 'tired'),
                ],
              ),
              const SizedBox(height: 20),
              const Text("ひとこと", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _noteController,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '今日の気分について書いてみよう',
                ),
                enabled: !hasRecordedToday,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedMood == null || hasRecordedToday) ? null : saveTodayMood,
                  child: const Text('今日の記録を保存する'),
                ),
              ),
              const SizedBox(height: 20),
              const Text("過去の記録", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final date = sortedDates.reversed.toList()[index];
                  final entry = moodLog[date];
                  return Card(
                    child: ListTile(
                      leading: Text(_emojiFor(entry['mood']), style: const TextStyle(fontSize: 24)),
                      title: Text(date),
                      subtitle: Text(entry['note']),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text("気分グラフ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  DropdownButton<int>(
                    value: selectedYear,
                    items: yearList
                        .map((y) => DropdownMenuItem(value: y, child: Text('$y年')))
                        .toList(),
                    onChanged: (val) => setState(() => selectedYear = val!),
                  ),
                  const SizedBox(width: 16),
                  DropdownButton<int>(
                    value: selectedMonth,
                    items: monthList
                        .map((m) => DropdownMenuItem(value: m, child: Text('$m月')))
                        .toList(),
                    onChanged: (val) => setState(() => selectedMonth = val!),
                  ),
                ],
              ),
              SizedBox(
                height: 200,
                child: BarChart(
                  BarChartData(
                    titlesData: FlTitlesData(
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 上の数字非表示
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false), // 右の数字非表示
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          interval: 1,
                          getTitlesWidget: (value, meta) {
                            if (value % 1 != 0) return Container(); // 0.5は非表示
                            if (value < 0) return Container();
                            return Text(value.toInt().toString());
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const labels = ['😞', '😴', '😐', '😊', '😀'];
                            if (value.toInt() < 0 || value.toInt() >= labels.length) return Container();
                            return Text(labels[value.toInt()], style: const TextStyle(fontSize: 16));
                          },
                        ),
                      ),
                    ),
                    barGroups: _generateBarChart(),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
