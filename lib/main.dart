import 'package:flutter/material.dart';

void main() {
  runApp(const MoodDiaryApp());
}

class MoodDiaryApp extends StatelessWidget {
  const MoodDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '気分日記',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

  @override
  void initState() {
    super.initState();
    _loadSampleData();
  }

  void _loadSampleData() {
    // サンプルデータを読み込む (SharedPreferencesの代わり)
    setState(() {
      moodLog = {
        '2025-05-10': {'mood': 'happy', 'note': 'とても良い日だった！'},
        '2025-05-11': {'mood': 'sad', 'note': '少し疲れていた'},
      };
    });
  }

  void saveTodayMood() {
    // コンテキストを事前にローカル変数に保存
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final today = DateTime.now().toIso8601String().split('T')[0];
    
    if (selectedMood == null) return;

    setState(() {
      moodLog[today] = {
        'mood': selectedMood,
        'note': _noteController.text
      };
      
      // 保存後にクリア
      _noteController.clear();
      selectedMood = null;
    });

    // フィードバック表示
    scaffoldMessenger.showSnackBar(
      const SnackBar(content: Text('気分を記録しました')),
    );
  }

  Widget buildMoodButton(String emoji, String mood) {
    return GestureDetector(
      onTap: () => setState(() => selectedMood = mood),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selectedMood == mood ? Colors.blue[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 32),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('気分日記'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const Text("ひとこと日記", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '今日の気分について書いてみよう',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: selectedMood == null ? null : saveTodayMood,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('今日の記録を保存する', style: TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            const Text("過去の記録", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: moodLog.isEmpty
                  ? const Center(child: Text('まだ記録がありません'))
                  : ListView.builder(
                      itemCount: moodLog.length,
                      itemBuilder: (context, index) {
                        final date = moodLog.keys.toList().reversed.toList()[index];
                        final entry = moodLog[date]!;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Text(
                              _emojiFor(entry['mood']),
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(date),
                            subtitle: Text(entry['note'] ?? ''),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
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
}
