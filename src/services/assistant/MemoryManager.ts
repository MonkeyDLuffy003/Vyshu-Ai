import { PersonalMemory, ProjectContext } from '../../types/assistant';

const STORAGE_KEYS = {
  PERSONAL_MEMORIES: 'vyshu_personal_memories_v2',
  PROJECT_CONTEXTS: 'vyshu_project_contexts_v2',
};

const DEFAULT_PROJECTS: ProjectContext[] = [
  {
    id: 'proj-1',
    projectName: 'Vyshu AI',
    description: 'Personal AI assistant system integrated as native phone interface layer for Teja.',
    activeStatus: 'Active Development',
    currentMilestone: 'Assistant Brain & Scheduler v2 Architecture',
    notes: [
      'Single user personalization for Teja.',
      'J.A.R.V.I.S.-style organic presence.',
      'Android companion APK architecture.',
    ],
  },
  {
    id: 'proj-2',
    projectName: 'Nisha AI',
    description: 'Autonomous research and data synthesis agent system.',
    activeStatus: 'Planning / Secondary',
    currentMilestone: 'Core specification complete',
    notes: ['Companion system to Vyshu.'],
  },
  {
    id: 'proj-3',
    projectName: 'Vayu',
    description: 'Environmental telemetry and sensor integration project.',
    activeStatus: 'Active Prototype',
    currentMilestone: 'Sensor packet protocol testing',
    notes: ['Telemetry pipeline for Teja.'],
  },
];

const DEFAULT_PERSONAL_MEMORIES: PersonalMemory[] = [
  {
    id: 'mem-1',
    category: 'personal',
    key: 'preferred_name',
    value: 'Teja (Sir in professional mode, Buddy or Teja in home/normal mode)',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'mem-2',
    category: 'routine',
    key: 'daily_hydration_goal',
    value: '3.5 Liters of water daily',
    createdAt: new Date().toISOString(),
  },
  {
    id: 'mem-3',
    category: 'routine',
    key: 'evening_wind_down',
    value: 'Quiet down tasks starting by 22:30',
    createdAt: new Date().toISOString(),
  },
];

export class MemoryManager {
  private static instance: MemoryManager;

  private constructor() {
    this.initDefaults();
  }

  public static getInstance(): MemoryManager {
    if (!MemoryManager.instance) {
      MemoryManager.instance = new MemoryManager();
    }
    return MemoryManager.instance;
  }

  private initDefaults(): void {
    if (!localStorage.getItem(STORAGE_KEYS.PROJECT_CONTEXTS)) {
      localStorage.setItem(STORAGE_KEYS.PROJECT_CONTEXTS, JSON.stringify(DEFAULT_PROJECTS));
    }
    if (!localStorage.getItem(STORAGE_KEYS.PERSONAL_MEMORIES)) {
      localStorage.setItem(STORAGE_KEYS.PERSONAL_MEMORIES, JSON.stringify(DEFAULT_PERSONAL_MEMORIES));
    }
  }

  // Personal Memories (explicitly saved by user)
  public getPersonalMemories(): PersonalMemory[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.PERSONAL_MEMORIES);
      return raw ? JSON.parse(raw) : DEFAULT_PERSONAL_MEMORIES;
    } catch {
      return DEFAULT_PERSONAL_MEMORIES;
    }
  }

  public savePersonalMemory(key: string, value: string, category: PersonalMemory['category'] = 'personal'): PersonalMemory {
    const list = this.getPersonalMemories();
    const existingIdx = list.findIndex((m) => m.key.toLowerCase() === key.toLowerCase());
    const mem: PersonalMemory = {
      id: `mem-${Date.now()}`,
      category,
      key,
      value,
      createdAt: new Date().toISOString(),
    };

    if (existingIdx >= 0) {
      list[existingIdx] = mem;
    } else {
      list.push(mem);
    }
    localStorage.setItem(STORAGE_KEYS.PERSONAL_MEMORIES, JSON.stringify(list));
    return mem;
  }

  // Project Memory
  public getProjects(): ProjectContext[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEYS.PROJECT_CONTEXTS);
      return raw ? JSON.parse(raw) : DEFAULT_PROJECTS;
    } catch {
      return DEFAULT_PROJECTS;
    }
  }

  public getProject(name: string): ProjectContext | undefined {
    const lower = name.toLowerCase().trim();
    return this.getProjects().find((p) => p.projectName.toLowerCase().includes(lower));
  }

  // Selective Context Retrieval (Avoids dumping entire DB into prompts)
  public retrieveRelevantContext(query: string): string {
    const lower = query.toLowerCase();
    const memories = this.getPersonalMemories();
    const projects = this.getProjects();

    const matchedMemories = memories.filter(
      (m) => lower.includes(m.key.toLowerCase()) || m.value.toLowerCase().split(' ').some((w: string) => w.length > 3 && lower.includes(w))
    );

    const matchedProjects = projects.filter(
      (p) => lower.includes(p.projectName.toLowerCase()) || lower.includes('project') || lower.includes('status')
    );

    const parts: string[] = [];

    if (matchedMemories.length > 0) {
      parts.push("RELEVANT USER PREFERENCES/MEMORIES:");
      matchedMemories.forEach((m) => parts.push(`- ${m.key}: ${m.value}`));
    }

    if (matchedProjects.length > 0) {
      parts.push("RELEVANT PROJECT CONTEXT:");
      matchedProjects.forEach((p) => parts.push(`- ${p.projectName} (${p.activeStatus}): ${p.description} [Current: ${p.currentMilestone}]`));
    }

    return parts.join("\n");
  }
}

export const memoryManager = MemoryManager.getInstance();
