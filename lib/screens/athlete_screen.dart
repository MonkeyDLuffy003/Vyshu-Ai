import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AthleteScreen extends StatefulWidget {
  const AthleteScreen({super.key});

  @override
  State<AthleteScreen> createState() => _AthleteScreenState();
}

class _AthleteScreenState extends State<AthleteScreen> {
  int _selectedDay = 0;
  double _waterLiters = 1.5;
  final double _waterGoal = 3.5;
  int _completedDays = 0;
  final List<bool> _completedList = List.generate(7, (index) => false);

  final List<Map<String, dynamic>> _schedule = [
    {
      'day': 'Mon',
      'title': 'Upper Body Foundation & Posture',
      'duration': '25-30 min',
      'exercises': [
        'Incline Push-ups (Hands on sofa/wall) — 3 sets x 8-10 reps',
        'Doorway Scapular Retractions (Back & Posture) — 3 sets x 12 reps',
        'Shoulder Wall Slides — 3 sets x 10 reps',
        'Brisk Walk — 15 mins (Cardio base)',
      ],
    },
    {
      'day': 'Tue',
      'title': 'Core Stability & Hip Mobility',
      'duration': '20-25 min',
      'exercises': [
        'Knee Planks (Abdominal bracing) — 3 sets x 20-30 sec',
        'Glute Bridges (Pelvic balance) — 3 sets x 12 reps',
        'Bird-Dog Balance — 3 sets x 8 reps/side',
        'Deep Hip Flexor Stretches — 3 mins',
      ],
    },
    {
      'day': 'Wed',
      'title': 'Active Recovery Walk & Hydration',
      'duration': '35 min',
      'isRest': true,
      'exercises': [
        'Outdoor Brisk Walk — 30-35 mins',
        'Full Body Dynamic Stretches — 10 mins',
        'Hydration Check: Hit 3.5L goal today',
      ],
    },
    {
      'day': 'Thu',
      'title': 'Lower Body Strength & Balance',
      'duration': '25-30 min',
      'exercises': [
        'Chair-Assisted Squats — 3 sets x 10-12 reps',
        'Reverse Lunges (Controlled) — 3 sets x 8 reps/leg',
        'Calf Raises (Step edge) — 3 sets x 15 reps',
        'Single-leg balance holds — 3 sets x 20 sec',
      ],
    },
    {
      'day': 'Fri',
      'title': 'Functional Bodyweight Circuit',
      'duration': '25 min',
      'exercises': [
        'Elevated Push-ups — 3 sets x 8 reps',
        'Quarter Squats to Calf Raise — 3 sets x 10 reps',
        'Deadbug Core Bracing — 3 sets x 10 reps',
        'Step Jacks (Low impact stamina) — 3 sets x 40 sec',
      ],
    },
    {
      'day': 'Sat',
      'title': 'Stamina & Agility Primer',
      'duration': '20-25 min',
      'exercises': [
        'Shadow Boxing (Jab-Cross rhythm) — 4 rounds x 2 mins',
        'High Knees March — 3 sets x 45 sec',
        'Torso Rotations & Side Bends — 3 sets x 15 reps',
        'Cool down walk — 10 mins',
      ],
    },
    {
      'day': 'Sun',
      'title': 'Rest, Recovery & Meal Prep',
      'duration': 'Full Rest',
      'isRest': true,
      'exercises': [
        'Gentle hamstring & chest stretching',
        'Review weekly rice adjustments',
        'Sleep 7-8 hours for full muscle recovery',
      ],
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterLiters = prefs.getDouble('vyshu_athlete_water') ?? 1.5;
      _completedDays = prefs.getInt('vyshu_athlete_completed') ?? 0;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('vyshu_athlete_water', _waterLiters);
    await prefs.setInt('vyshu_athlete_completed', _completedDays);
  }

  void _toggleComplete(int index) {
    setState(() {
      _completedList[index] = !_completedList[index];
      _completedDays = _completedList.where((c) => c).length;
    });
    _saveState();
  }

  void _addWater(double amount) {
    setState(() {
      _waterLiters = (_waterLiters + amount).clamp(0.0, _waterGoal);
    });
    _saveState();
  }

  @override
  Widget build(BuildContext context) {
    final current = _schedule[_selectedDay];

    return Scaffold(
      backgroundColor: const Color(0xFF070914),
      appBar: AppBar(
        backgroundColor: const Color(0xFF090D24),
        title: const Row(
          children: [
            Icon(Icons.fitness_center, color: Color(0xFF00CCFF), size: 20),
            SizedBox(width: 8),
            Text(
              'Vyshu Athlete Coach',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B2027), Color(0xFF090D24)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00CCFF).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.4)),
                        ),
                        child: const Text(
                          'PHASE 1: FOUNDATION • WEEK 1',
                          style: TextStyle(color: Color(0xFF00CCFF), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        'Sessions: $_completedDays/7',
                        style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Target: Athletic Indian Hero Physique',
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '"Build muscle that you can use." Lean waist, broad V-taper shoulders, functional stamina. Calibrated for 25y, 170cm, 82kg.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Week Day Selector
            SizedBox(
              height: 52,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _schedule.length,
                itemBuilder: (context, idx) {
                  final item = _schedule[idx];
                  final isSelected = _selectedDay == idx;
                  final isDone = _completedList[idx];

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDay = idx),
                    child: Container(
                      width: 48,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF00CCFF).withOpacity(0.25)
                            : isDone
                                ? const Color(0xFF00E676).withOpacity(0.15)
                                : const Color(0xFF0D1226),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF00CCFF)
                              : isDone
                                  ? const Color(0xFF00E676).withOpacity(0.4)
                                  : Colors.white12,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item['day'] as String,
                            style: TextStyle(
                              color: isSelected ? const Color(0xFF00CCFF) : Colors.white70,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isDone ? '✓' : '${idx + 1}',
                            style: TextStyle(
                              color: isDone ? const Color(0xFF00E676) : Colors.white,
                              fontSize: 12,
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

            const SizedBox(height: 16),

            // Day Routine Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F26),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.between,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              current['title'] as String,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Duration: ${current['duration']} • Home / Zero Equipment',
                              style: const TextStyle(color: Color(0xFF00CCFF), fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _completedList[_selectedDay] ? Icons.check_circle : Icons.check_circle_outline,
                          color: _completedList[_selectedDay] ? const Color(0xFF00E676) : Colors.white38,
                          size: 28,
                        ),
                        onPressed: () => _toggleComplete(_selectedDay),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white12),
                  const SizedBox(height: 8),
                  ...(current['exercises'] as List<String>).map(
                    (ex) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.play_arrow, color: Color(0xFF00CCFF), size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              ex,
                              style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Hydration Tracker
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F26),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF00CCFF).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.water_drop, color: Color(0xFF00CCFF), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Water: ${_waterLiters.toStringAsFixed(1)} / ${_waterGoal.toStringAsFixed(1)} L',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: _waterLiters / _waterGoal,
                            backgroundColor: Colors.white12,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF00CCFF)),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () => _addWater(0.25),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00CCFF),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: const Size(40, 32),
                    ),
                    child: const Text('+250ml', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Home Indian Food Adjustment Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0F26),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant, color: Color(0xFF00CCFF), size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Indian Home Diet Rule (Rice Shift)',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '1. Replace 25% of your white rice mound with extra Dal, Sambar, or Chana.\n'
                    '2. Eat 1 raw cucumber or tomato slice 5 mins before meals to control insulin & appetite.\n'
                    '3. Add 2 boiled eggs or 50g paneer daily for lean muscle preservation.',
                    style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
