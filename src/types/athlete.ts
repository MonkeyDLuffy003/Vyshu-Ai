export interface AthleteProfile {
  age: number;
  heightCm: number;
  weightKg: number;
  targetLook: string;
  focusAreas: string[];
  startingCondition: string;
  foodContext: string;
  waterGoalLiters: number;
  waterCurrentLiters: number;
  ricePortionNote: string;
  currentPhase: 1 | 2 | 3;
  currentWeek: number;
  completedWorkouts: number;
  streakDays: number;
  lastWorkoutDate?: string;
  weeklySchedule: {
    day: string;
    focus: string;
    duration: string;
    exercises: string[];
    isRest?: boolean;
    completed?: boolean;
  }[];
}

export const DEFAULT_ATHLETE_PROFILE: AthleteProfile = {
  age: 25,
  heightCm: 170,
  weightKg: 82,
  targetLook: 'Athletic Indian Hero (Dhruva lean athletic cut + Prabhas presence)',
  focusAreas: ['Leaner waist & hip fat reduction', 'V-Taper shoulders & back', 'Chest & arm definition', 'Core & posture', 'Functional stamina'],
  startingCondition: 'Beginner • Higher abdominal fat • Less fat on arms • No initial equipment',
  foodContext: 'Normal home-cooked Indian meals with moderate rice adjustments & high protein additions',
  waterGoalLiters: 3.5,
  waterCurrentLiters: 1.5,
  ricePortionNote: 'Gradually replace 25-30% of white rice plate with dal, boiled eggs/paneer, cucumbers & green salad',
  currentPhase: 1,
  currentWeek: 1,
  completedWorkouts: 0,
  streakDays: 0,
  weeklySchedule: [
    {
      day: 'Monday',
      focus: 'Upper Body Foundation & Posture',
      duration: '25-30 mins',
      exercises: [
        'Incline Push-ups (Hands on wall or sofa) — 3 sets x 8-10 reps',
        'Doorway Chest Openers & Scapular Squeezes — 3 sets x 12 reps',
        'Arm Circles & Shoulder Wall Slides — 3 sets x 10 reps',
        'Brisk Walk — 15 mins (stamina base)',
      ],
    },
    {
      day: 'Tuesday',
      focus: 'Core Stability & Hip Mobility',
      duration: '20-25 mins',
      exercises: [
        'Knee Planks (Core engagement) — 3 sets x 20-30 secs',
        'Glute Bridges (Pelvic & hip stability) — 3 sets x 12 reps',
        'Bird-Dog (Lower back & coordination) — 3 sets x 8 reps/side',
        'Deep Hip Flexor Stretches — 3 mins',
      ],
    },
    {
      day: 'Wednesday',
      focus: 'Active Recovery & Cardio Walk',
      duration: '30-40 mins',
      isRest: true,
      exercises: [
        'Outdoor Brisk Walk or Paced Treadmill — 30-40 mins',
        'Full Body Dynamic Mobility Routine — 10 mins',
        'Hydration Check: Reach 3+ Liters today',
      ],
    },
    {
      day: 'Thursday',
      focus: 'Lower Body Strength & Balance',
      duration: '25-30 mins',
      exercises: [
        'Chair Assisted Squats — 3 sets x 10-12 reps',
        'Reverse Lunges (Step back slow) — 3 sets x 8 reps/leg',
        'Standing Calf Raises (Edge of step) — 3 sets x 15 reps',
        'Standing Single-Leg Balance Holds — 3 sets x 20 secs/leg',
      ],
    },
    {
      day: 'Friday',
      focus: 'Functional Full-Body Circuit',
      duration: '25-30 mins',
      exercises: [
        'Elevated Push-ups — 3 sets x 8 reps',
        'Bodyweight Quarter Squats to Calf Raise — 3 sets x 10 reps',
        'Deadbug Abdominal Bracing — 3 sets x 10 reps',
        'Paced Step Jacks (Low-impact cardio) — 3 sets x 40 secs',
      ],
    },
    {
      day: 'Saturday',
      focus: 'Stamina & Agility Primer',
      duration: '20-25 mins',
      exercises: [
        'Shadow Boxing Light Combinations (Jab-Cross) — 4 rounds x 2 mins',
        'High Knees March (Low impact) — 3 sets x 45 secs',
        'Torso Rotations & Side Bends — 3 sets x 15 reps',
        'Paced Cool Down Walk — 10 mins',
      ],
    },
    {
      day: 'Sunday',
      focus: 'Full Rest & Recovery Coaching',
      duration: 'Relax & Recharge',
      isRest: true,
      exercises: [
        'Gentle hamstring & chest stretching',
        'Hydration tracking review with Vyshu',
        'Sleep 7-8 hours for full muscle repair',
      ],
    },
  ],
};
