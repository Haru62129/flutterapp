import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// --- 目標リスト ---
const List<String> weeklyGoals = [
  '毎日記録チャレンジ',
  '週5日以上記録',
  '3週連続記録',
  '深夜じゃない記録',
  'ポジティブ気分ウィーク',
  '平常心を保つ',
  'メモ習慣スタート',
  '書くことで整理',
  '【高難度】気分の虹',
  '【高難度】夜更かし記録王',
  '【高難度】毎日メモウィーク',
  '【高難度】長文メモに挑戦',
  '【高難度】一言で気分表現',
  '【高難度】気分パターン職人',
  '【高難度】交互の達人',
  '【高難度】一喜一憂職人',
  '【高難度】怒りの制御者',
  '【高難度】寝ても覚めても疲れた',
  '【高難度】冷静沈着マスター',
  '【高難度】バランスの達人',
  '【高難度】感情の迷路',
  '【高難度】感情ルーティン修行僧',
  '【高難度】昨日を超える者',
  '【高難度】沈黙の観察者',
  '【超高難度】二重達成',
  '【超高難度】すべて違う記録時間',
  '【超高難度】メモで語る',
  '【超高難度】気分アーティスト',
  '【超高難度】静と動の均衡',
  '【超高難度】感情の錬金術師',
  '【超高難度】沈黙の記録者',
  '【超高難度】無敗の継続王',
];

// --- 達成条件マップ ---
const Map<String, String> goalConditionMap = {
  '毎日記録チャレンジ': '1週間毎日記録をつける',
  '週5日以上記録': '週に5日以上記録する',
  '3週連続記録': '3週連続で週5日以上記録',
  '深夜じゃない記録': '5日間、深夜0時前に記録',
  'ポジティブ気分ウィーク': '1週間のうち4日以上😊を選択',
  '平常心を保つ': '1週間のうち5日以上😐を選択',
  'メモ習慣スタート': '3日連続でメモを記入する',
  '書くことで整理': '週5日以上メモを記入',
  '【高難度】気分の虹': '6日連続で違う気分を記録',
  '【高難度】夜更かし記録王': '一週間、深夜0時以降に記録',
  '【高難度】毎日メモウィーク': '7日間すべてでメモを記入',
  '【高難度】長文メモに挑戦': '週に3回以上、メモが100文字以上',
  '【高難度】一言で気分表現': '3日間連続でメモが20文字未満（意図的に短く）',
  '【高難度】気分パターン職人': '3日連続で同じ気分を記録（例：😐😐😐）',
  '【高難度】交互の達人': '5日間、😊と😞を交互に記録（例：😊😞😊😞😊）',
  '【高難度】一喜一憂職人': '3日連続で🤩と😢のみを交互に記録する（例：🤩😢🤩）',
  '【高難度】怒りの制御者': '😡を記録した翌日に😄または😐でリカバリーを3回以上成功',
  '【高難度】寝ても覚めても疲れた': '😴を5日以上連続で記録する（例：😴😴😴😴😴）',
  '【高難度】冷静沈着マスター': '1週間連続で😐を記録',
  '【高難度】バランスの達人': '🤩😄😐😢😡😴の順で1日ずつ記録する（6日間で1周）',
  '【高難度】感情の迷路': '3日間、毎日異なる気分を記録する（例：😐😡😴）',
  '【高難度】感情ルーティン修行僧': '「😐→😄→😴→😐→😄→😴→😐」の順で記録（1週間）',
  '【高難度】昨日を超える者': '昨日より「前向き」な気分を3日連続で記録（例：😢→😐→😄）',
  '【高難度】沈黙の観察者': '😐を4日間以上記録し、メモで「何も感じなかった理由」を書く',
  '【超高難度】二重達成': '同じ週に「気分の虹」と「毎日メモウィーク」を同時に達成',
  '【超高難度】すべて違う記録時間': '1週間で記録した時間帯がすべて異なる（例：7時、10時、14時、17時、21時、23時、1時）',
  '【超高難度】メモで語る': 'すべての気分で100文字以上のメモを記録した週',
  '【超高難度】気分アーティスト': '30日間、1日も欠かさず気分を記録し、6種類すべての気分を最低3回ずつ使う',
  '【超高難度】静と動の均衡': '14日間、活発系（🤩😄）と静寂系（😐😴）の気分を交互に記録し続ける',
  '【超高難度】感情の錬金術師': '1週間で「😡」を記録した翌日に必ず「😄」または「😐」を記録し、メモでその理由も書く（毎日）',
  '【超高難度】沈黙の記録者': '7日間連続で😐を記録し、全日メモ付き＆他の感情は記録しない',
  '【超高難度】無敗の継続王': '60日間連続で気分を記録し、1日も抜けなし',
};

// --- バッジアイコンマップ ---
const Map<String, IconData> goalBadgeMap = {
  '毎日記録チャレンジ': Icons.menu_book,
  '週5日以上記録': Icons.calendar_today,
  '3週連続記録': Icons.emoji_events,
  '深夜じゃない記録': Icons.nightlight_round,
  'ポジティブ気分ウィーク': Icons.wb_iridescent,
  '平常心を保つ': Icons.self_improvement,
  'メモ習慣スタート': Icons.edit,
  '書くことで整理': Icons.edit_note,
  '【高難度】気分の虹': Icons.brightness_7,
  '【高難度】夜更かし記録王': Icons.nights_stay,
  '【高難度】毎日メモウィーク': Icons.menu_book,
  '【高難度】長文メモに挑戦': Icons.search,
  '【高難度】一言で気分表現': Icons.cut,
  '【高難度】気分パターン職人': Icons.repeat,
  '【高難度】交互の達人': Icons.swap_horiz,
  '【高難度】一喜一憂職人': Icons.waves,
  '【高難度】怒りの制御者': Icons.explore,
  '【高難度】寝ても覚めても疲れた': Icons.king_bed,
  '【高難度】冷静沈着マスター': Icons.ac_unit,
  '【高難度】バランスの達人': Icons.balance,
  '【高難度】感情の迷路': Icons.blur_circular,
  '【高難度】感情ルーティン修行僧': Icons.self_improvement,
  '【高難度】昨日を超える者': Icons.trending_up,
  '【高難度】沈黙の観察者': Icons.search,
  '【超高難度】二重達成': Icons.all_inclusive,
  '【超高難度】すべて違う記録時間': Icons.theater_comedy,
  '【超高難度】メモで語る': Icons.auto_fix_high,
  '【超高難度】気分アーティスト': Icons.palette,
  '【超高難度】静と動の均衡': Icons.balance,
  '【超高難度】感情の錬金術師': Icons.science,
  '【超高難度】沈黙の記録者': Icons.do_not_disturb_on,
  '【超高難度】無敗の継続王': Icons.emoji_events,
};

// テーマ
enum ThemeType {
  springMorning,
  springNight,
  summerMorning,
  summerNight,
  autumnMorning,
  autumnNight,
  winterMorning,
  winterNight,
}

const Map<ThemeType, String> themeJapaneseName = {
  ThemeType.springMorning: '春・朝',
  ThemeType.springNight: '春・夜',
  ThemeType.summerMorning: '夏・朝',
  ThemeType.summerNight: '夏・夜',
  ThemeType.autumnMorning: '秋・朝',
  ThemeType.autumnNight: '秋・夜',
  ThemeType.winterMorning: '冬・朝',
  ThemeType.winterNight: '冬・夜',
};

// --- メイン関数 ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja');
  runApp(const MoodDiaryApp());
}

class MoodDiaryApp extends StatefulWidget {
  const MoodDiaryApp({super.key});
  @override
  State<MoodDiaryApp> createState() => _MoodDiaryAppState();
}

class _MoodDiaryAppState extends State<MoodDiaryApp> {
  ThemeType? selectedTheme;
  @override
  Widget build(BuildContext context) {
    final themeType = selectedTheme ?? getCurrentThemeType();
    return MaterialApp(
      title: 'きぶん日記',
      theme: getThemeData(themeType),
      home: MoodHomePage(
        onThemeChanged: (t) => setState(() => selectedTheme = t),
        selectedTheme: selectedTheme,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MoodHomePage extends StatefulWidget {
  final void Function(ThemeType?) onThemeChanged;
  final ThemeType? selectedTheme;
  const MoodHomePage({super.key, required this.onThemeChanged, required this.selectedTheme});
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
  int? selectedWeek;
  final List<int?> weekFilterOptions = [null, 1, 2, 3, 4, 5];

  String? selectedMoodFilter;

  late AnimationController _msgController;
  late Animation<double> _msgAnimation;

  String? selectedWeeklyGoal;
  bool goalAchieved = false;
  Set<String> achievedBadges = {};

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
    _loadGoalPrefs();

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

  Future<void> _loadGoalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final loadedGoal = prefs.getString('selectedWeeklyGoal');
    setState(() {
      selectedWeeklyGoal = (loadedGoal == null || loadedGoal.isEmpty) ? null : loadedGoal;
      goalAchieved = prefs.getBool('goalAchieved') ?? false;
      achievedBadges = (prefs.getStringList('achievedBadges') ?? []).toSet();
    });
    checkGoalAchievement();
  }

  Future<void> _saveGoalPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selectedWeeklyGoal', selectedWeeklyGoal ?? '');
    await prefs.setBool('goalAchieved', goalAchieved);
    await prefs.setStringList('achievedBadges', achievedBadges.toList());
  }

  Future<void> saveTodayMood() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final today = DateTime.now().toIso8601String().split('T')[0];

    if (selectedMood == null || hasRecordedToday) return;

    setState(() {
      moodLog[today] = {
        'mood': selectedMood,
        'note': _noteController.text,
        'imagePath': null,
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

    _showMessagePopup(moodLog[today]!['mood']);
    checkGoalAchievement();
    await _saveGoalPrefs();
  }

  void checkGoalAchievement() {
    if (selectedWeeklyGoal == null) {
      setState(() => goalAchieved = false);
      return;
    }
    // 例：毎日記録チャレンジ
    if (selectedWeeklyGoal == '毎日記録チャレンジ') {
      final now = DateTime.now();
      final weekDays = List.generate(7, (i) =>
          DateTime(now.year, now.month, now.day - now.weekday + 1 + i));
      final dates = weekDays.map((d) => d.toIso8601String().split('T')[0]);
      final achieved = dates.every((d) => moodLog.containsKey(d));
      setState(() {
        goalAchieved = achieved;
        if (achieved) achievedBadges.add(selectedWeeklyGoal!);
      });
      return;
    }
    if (selectedWeeklyGoal == '週5日以上記録') {
      final now = DateTime.now();
      final weekDays = List.generate(7, (i) =>
          DateTime(now.year, now.month, now.day - now.weekday + 1 + i));
      final dates = weekDays.map((d) => d.toIso8601String().split('T')[0]);
      final count = dates.where((d) => moodLog.containsKey(d)).length;
      final achieved = count >= 5;
      setState(() {
        goalAchieved = achieved;
        if (achieved) achievedBadges.add(selectedWeeklyGoal!);
      });
      return;
    }
    // 他の目標達成ロジックも同様に分岐して実装してください
  }

  void _showBadgeListDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('バッジ一覧'),
        content: SizedBox(
          width: 350,
          child: ListView(
            shrinkWrap: true,
            children: weeklyGoals.map((goal) {
              final achieved = achievedBadges.contains(goal);
              return ListTile(
                leading: Icon(goalBadgeMap[goal] ?? Icons.stars,
                    color: achieved ? Colors.amber : Colors.grey),
                title: Text(goal),
                subtitle: Text(goalConditionMap[goal] ?? '', style: const TextStyle(fontSize: 12)),
                trailing: achieved
                    ? const Text('獲得', style: TextStyle(color: Colors.amber))
                    : const Text('未獲得', style: TextStyle(color: Colors.grey)),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('閉じる'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget buildThemeSelector() {
    return Row(
      children: [
        const Text('テーマ:'),
        DropdownButton<ThemeType>(
          value: widget.selectedTheme,
          hint: const Text('自動'),
          items: ThemeType.values.map((t) => DropdownMenuItem(
            value: t,
            child: Text(themeJapaneseName[t]!),
          )).toList(),
          onChanged: widget.onThemeChanged,
        ),
      ],
    );
  }

  Widget buildFilterSection() {
    final now = DateTime.now();
    final isSpring = isSpringTheme(widget.selectedTheme ?? getCurrentThemeType());
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                      selectedWeek = null;
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
                      selectedWeek = null;
                      _loadMoodLog();
                    });
                  }
                },
              ),
              const SizedBox(width: 12),
              DropdownButton<int?>(
                value: selectedWeek,
                hint: const Text('週'),
                items: weekFilterOptions.map((i) => DropdownMenuItem(
                  value: i,
                  child: Text(i == null ? 'すべて' : '第${i}週'),
                )).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedWeek = val;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                    color: selectedMoodFilter == e.key
                        ? (isSpring ? Colors.pink[100] : Colors.orange[100])
                        : Colors.grey.shade200,
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
        ],
      ),
    );
  }

  List<MapEntry<String, dynamic>> _getFilteredMoodLog() {
    final filteredEntries = moodLog.entries.where((entry) {
      final date = DateTime.parse(entry.key);
      final matchesDate = date.year == selectedYear && date.month == selectedMonth;
      final matchesMood = selectedMoodFilter == null || entry.value['mood'] == selectedMoodFilter;
      final firstDay = DateTime(date.year, date.month, 1);
      final firstWeekday = firstDay.weekday % 7;
      final weekNumber = ((date.day + firstWeekday - 1) / 7).floor() + 1;
      final matchesWeek = selectedWeek == null || weekNumber == selectedWeek;
      return matchesDate && matchesMood && matchesWeek;
    }).toList();
    filteredEntries.sort((a, b) => b.key.compareTo(a.key));
    return filteredEntries;
  }

  Widget _buildMemoList() {
    final filteredEntries = _getFilteredMoodLog();
    final isSpring = isSpringTheme(widget.selectedTheme ?? getCurrentThemeType());
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
        return GestureDetector(
          onTap: () => _showEditMemoDialog(entry.key, moodData),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSpring ? Colors.pink.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSpring ? Colors.pink.shade100 : Colors.orange.shade100),
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
                        color: isSpring ? Colors.pink.shade200 : Colors.orange.shade200,
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
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showEditMemoDialog(String dateKey, Map<String, dynamic> moodData) async {
    String? editMood = moodData['mood'];
    final TextEditingController editNoteController = TextEditingController(text: moodData['note']);
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
                        backgroundColor: editMood == e.key
                            ? (isSpringTheme(widget.selectedTheme ?? getCurrentThemeType())
                                ? Colors.pink
                                : Colors.orange)
                            : Colors.grey.shade200,
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
                    'imagePath': null,
                  };
                });
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('moodLog', jsonEncode(moodLog));
                Navigator.pop(context);
                checkGoalAchievement();
                await _saveGoalPrefs();
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
                checkGoalAchievement();
                await _saveGoalPrefs();
              },
            ),
          ],
        ),
      ),
    );
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

  String formatWeekLabel(DateTime date) {
    final firstDay = DateTime(date.year, date.month, 1);
    final firstWeekday = firstDay.weekday % 7;
    final weekNumber = ((date.day + firstWeekday - 1) / 7).floor() + 1;
    return '${date.month}月第$weekNumber週';
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
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
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

  @override
  Widget build(BuildContext context) {
    final moodFrequency = _generateMoodFrequencyByWeek();
    final themeType = widget.selectedTheme ?? getCurrentThemeType();
    final isNight = themeType == ThemeType.springNight ||
        themeType == ThemeType.summerNight ||
        themeType == ThemeType.autumnNight ||
        themeType == ThemeType.winterNight;
    final isSpring = isSpringTheme(themeType);

    Color labelTextColor;
    if (themeType == ThemeType.springMorning) {
      labelTextColor = const Color(0xFF4B2C5E);
    } else if (themeType == ThemeType.springNight) {
      labelTextColor = const Color(0xFFCA7FC2);
    } else if (themeType == ThemeType.autumnMorning) {
      labelTextColor = const Color(0xFF7B4B11);
    } else if (themeType == ThemeType.autumnNight) {
      labelTextColor = const Color(0xFFDACB93);
    } else {
      labelTextColor = Colors.black;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('きぶん日記', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: buildThemeSelector(),
          ),
        ],
        backgroundColor: isSpring ? Colors.pink : Colors.orange,
        centerTitle: true,
        elevation: 2,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          children: [
            Card(
              margin: const EdgeInsets.symmetric(vertical: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('今週の目標', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.emoji_events, color: Colors.amber),
                          label: const Text('バッジ一覧'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.amber.shade700),
                            foregroundColor: Colors.amber.shade800,
                          ),
                          onPressed: _showBadgeListDialog,
                        ),
                      ],
                    ),
                    DropdownButton<String>(
                      value: (selectedWeeklyGoal != null && selectedWeeklyGoal!.isNotEmpty && weeklyGoals.contains(selectedWeeklyGoal))
                          ? selectedWeeklyGoal
                          : null,
                      hint: const Text('目標を選択'),
                      items: weeklyGoals.map((goal) => DropdownMenuItem(
                        value: goal,
                        child: Text(goal),
                      )).toList(),
                      onChanged: (value) async {
                        setState(() {
                          selectedWeeklyGoal = value;
                          goalAchieved = false;
                        });
                        checkGoalAchievement();
                        await _saveGoalPrefs();
                      },
                    ),
                    if (selectedWeeklyGoal != null)
                      Row(
                        children: [
                          const Text('達成バッジ:'),
                          Icon(goalBadgeMap[selectedWeeklyGoal!] ?? Icons.stars, color: goalAchieved ? (isSpring ? Colors.pink : Colors.orange) : Colors.grey),
                          if (goalAchieved)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Text('達成！', style: TextStyle(color: isSpring ? Colors.pink : Colors.orange,fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: hasRecordedToday
                    ? const Center(child: Text('本日はすでに記録済みです', style: TextStyle(color: Colors.grey, fontSize: 16)))
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('気分を選んでください', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 14),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      children: moodEmojiMap.entries.map((e) => GestureDetector(
                        onTap: () => setState(() => selectedMood = e.key),
                        child: CircleAvatar(
                          backgroundColor: selectedMood == e.key ? (isSpring ? Colors.pink.shade200 : Colors.orange.shade200) : Colors.grey.shade200,
                          radius: 26,
                          child: Text(e.value, style: const TextStyle(fontSize: 30)),
                        ),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _noteController,
                      decoration: InputDecoration(
                        labelText: 'メモ（任意）',
                        labelStyle: TextStyle(
                          color: isNight
                              ? Colors.black
                              : labelTextColor,
                        ),
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      style: const TextStyle(color: Colors.black),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text('記録する', style: TextStyle(fontSize: 18)),
                      onPressed: selectedMood == null ? null : saveTodayMood,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isSpring ? Colors.pink : Colors.orange,
                        foregroundColor: Colors.black,
                        minimumSize: const Size.fromHeight(44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            buildFilterSection(),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 16, left: 4, bottom: 8),
                child: Text(
                  'メモ一覧（タップで編集）',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isSpring
                        ? Colors.pink.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ),
            _buildMemoList(),
            Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: SizedBox(
                height: 260,
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
                            color: isSpring ? Colors.pink : Colors.orange,
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
            ),
          ],
        ),
      ),
    );
  }
}

bool isSpringTheme(ThemeType t) => t == ThemeType.springMorning || t == ThemeType.springNight;

ThemeType getCurrentThemeType() {
  final now = DateTime.now();
  final hour = now.hour;
  final month = now.month;
  bool isMorning = (hour >= 5 && hour < 17);
  if (month >= 3 && month <= 5) return isMorning ? ThemeType.springMorning : ThemeType.springNight;
  if (month >= 6 && month <= 8) return isMorning ? ThemeType.summerMorning : ThemeType.summerNight;
  if (month >= 9 && month <= 11) return isMorning ? ThemeType.autumnMorning : ThemeType.autumnNight;
  return isMorning ? ThemeType.winterMorning : ThemeType.winterNight;
}

ThemeData getThemeData(ThemeType type) {
  switch (type) {
    case ThemeType.springMorning:
      return ThemeData(
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFFFFF4F8),
        primaryColor: const Color(0xFFF8BBD0),
        appBarTheme: const AppBarTheme(color: Color(0xFFF8BBD0)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink)
            .copyWith(secondary: const Color(0xFFF8BBD0)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF06292),
        ),
        dividerColor: const Color(0xFFE1BEE7),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF4B2C5E)),
          titleLarge: TextStyle(color: Color(0xFF4B2C5E)),
        ),
      );
    case ThemeType.springNight:
      return ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFF5D365C),
        primaryColor: const Color(0xFFB97A95),
        appBarTheme: const AppBarTheme(color: Color(0xFF5D365C)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.pink,
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFFF8BBD0)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFB97A95),
        ),
        dividerColor: const Color(0xFFB97A95),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFCA7FC2)),
          titleLarge: TextStyle(color: Color(0xFFCA7FC2)),
        ),
      );
    case ThemeType.summerMorning:
      return ThemeData(
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFFE7F9FD),
        primaryColor: const Color(0xFF6ECEDA),
        appBarTheme: const AppBarTheme(color: Color(0xFF43B6C7)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.teal)
            .copyWith(secondary: const Color(0xFFFFE066)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF43B6C7),
        ),
        dividerColor: const Color(0xFFB2EBF2),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF0B7285)),
          titleLarge: TextStyle(color: Color(0xFF0B7285)),
        ),
      );
    case ThemeType.summerNight:
      return ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFF274472),
        primaryColor: const Color(0xFF6ECEDA),
        appBarTheme: const AppBarTheme(color: Color(0xFF274472)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.teal,
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFF6ECEDA)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6ECEDA),
        ),
        dividerColor: const Color(0xFF3A8891),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFE7F9FD)),
          titleLarge: TextStyle(color: Color(0xFFE7F9FD)),
        ),
      );
    case ThemeType.autumnMorning:
      return ThemeData(
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFFFFF7E6),
        primaryColor: const Color(0xFFF4A259),
        appBarTheme: const AppBarTheme(color: Color(0xFFD9643A)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepOrange)
            .copyWith(secondary: const Color(0xFF6E3B0B)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFD9643A),
        ),
        dividerColor: const Color(0xFFFFD180),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF7B4B11)),
          titleLarge: TextStyle(color: Color(0xFF7B4B11)),
        ),
      );
    case ThemeType.autumnNight:
      return ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFF362222),
        primaryColor: const Color(0xFFF4A259),
        appBarTheme: const AppBarTheme(color: Color(0xFF362222)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.deepOrange,
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFFF4A259)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF4A259),
        ),
        dividerColor: const Color(0xFFD9643A),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFDACB93)),
          titleLarge: TextStyle(color: Color(0xFFDACB93)),
        ),
      );
    case ThemeType.winterMorning:
      return ThemeData(
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFFF4F6FB),
        primaryColor: const Color(0xFF6A9CFD),
        appBarTheme: const AppBarTheme(color: Color(0xFF506FA1)),
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue)
            .copyWith(secondary: const Color(0xFFC8D6E5)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF506FA1),
        ),
        dividerColor: const Color(0xFFB3C6E5),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFF2B3A55)),
          titleLarge: TextStyle(color: Color(0xFF2B3A55)),
        ),
      );
    case ThemeType.winterNight:
      return ThemeData(
        brightness: Brightness.dark,
        fontFamily: 'MPLUSRounded1c',
        scaffoldBackgroundColor: const Color(0xFF222831),
        primaryColor: const Color(0xFF6A9CFD),
        appBarTheme: const AppBarTheme(color: Color(0xFF222831)),
        colorScheme: ColorScheme.fromSwatch(
          primarySwatch: Colors.blue,
          brightness: Brightness.dark,
        ).copyWith(secondary: const Color(0xFF6A9CFD)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF6A9CFD),
        ),
        dividerColor: const Color(0xFF506FA1),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Color(0xFFF4F6FB)),
          titleLarge: TextStyle(color: Color(0xFFF4F6FB)),
        ),
      );
  }
}