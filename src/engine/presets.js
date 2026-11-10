export const BASES = {
  male: { label: 'Masculino', url: '/models/quaternius/Superhero_Male.gltf', hair: 'short' },
  female: { label: 'Feminino', url: '/models/quaternius/Superhero_Female.gltf', hair: 'long' },
};

export const RACES = {
  human: {
    label: 'Humano', icon: '🧑',
    colors: { skin: '#d8a98c', eyes: '#4a7a3a', hair: '#3a2519', cloth: '#2b3a55' },
    mods: { height: 1, muscle: 0, fat: 0, chest: 1, head: 1, arms: 1, legs: 1 },
    hair: 'short', parts: [],
    posture: { spine: 0, neck: 0, head: 0 },
  },
  orc: {
    label: 'Orc', icon: '👹',
    colors: { skin: '#6f9a45', eyes: '#e8b814', hair: '#15110d', cloth: '#5a3d24' },
    mods: { height: 1.1, muscle: 0.55, fat: 0.1, chest: 1.12, head: 1.05, arms: 1.1, legs: 0.92 },
    hair: 'none', parts: ['orc'],
    posture: { spine: 0.12, neck: 0.1, head: -0.14 },
  },
  werewolf: {
    label: 'Lobisomem', icon: '🐺',
    colors: { skin: '#8c6a4d', eyes: '#ffb21a', hair: '#3a2a1d', cloth: '#3b2b20' },
    mods: { height: 1.18, muscle: 0.45, fat: 0, chest: 1.1, head: 1.0, arms: 1.15, legs: 1.04 },
    hair: 'none', parts: ['wolf'],
    posture: { spine: 0.28, neck: 0.18, head: -0.3 },
  },
};

export const SLIDERS = [
  { key: 'height', label: 'Altura', min: 0.8, max: 1.25, step: 0.01, def: 1, fmt: (v, mods) => `${(1.8 * v * (mods?.height ?? 1)).toFixed(2)} m` },
  { key: 'muscle', label: 'Massa muscular', min: 0, max: 1, step: 0.01, def: 0.15, fmt: (v) => `${Math.round(v * 100)}%` },
  { key: 'fat', label: 'Peso corporal', min: 0, max: 1, step: 0.01, def: 0.1, fmt: (v) => `${Math.round(v * 100)}%` },
  { key: 'chest', label: 'Peito / ombros', min: 0.85, max: 1.25, step: 0.01, def: 1, fmt: (v) => `${Math.round(v * 100)}%` },
  { key: 'head', label: 'Tamanho da cabeça', min: 0.8, max: 1.3, step: 0.01, def: 1, fmt: (v) => `${Math.round(v * 100)}%` },
  { key: 'arms', label: 'Comprimento dos braços', min: 0.85, max: 1.25, step: 0.01, def: 1, fmt: (v) => `${Math.round(v * 100)}%` },
  { key: 'legs', label: 'Comprimento das pernas', min: 0.85, max: 1.25, step: 0.01, def: 1, fmt: (v) => `${Math.round(v * 100)}%` },
];

export const HAIR_STYLES = [
  { id: 'none', label: 'Nenhum' },
  { id: 'short', label: 'Curto' },
  { id: 'long', label: 'Longo' },
];

export const SKIN_SWATCHES = ['#f1d3bd', '#d8a98c', '#b57d5a', '#8a5a3c', '#5e3b26', '#6f9a45', '#8c6a4d', '#7aa6c2'];
export const HAIR_SWATCHES = ['#0f0b09', '#3a2519', '#7a4a24', '#c9a15a', '#d8d2c8', '#9b2d20', '#3a3f8a', '#2a1d14'];
export const CLOTH_SWATCHES = ['#2b3a55', '#5a3d24', '#3b2b20', '#7a1f1f', '#1d1d1f', '#d9d4c7', '#2f5d3a', '#6b3fa0'];
export const EYE_SWATCHES = ['#4a7a3a', '#3b6fd0', '#5a3a1c', '#6b6b6b', '#ffb21a', '#e8b814', '#c0392b', '#7b3fe4'];

export const defaultSliders = () => Object.fromEntries(SLIDERS.map((s) => [s.key, s.def]));

export function defaultState(base = 'male', race = 'human') {
  const r = RACES[race];
  return {
    base,
    race,
    sliders: defaultSliders(),
    colors: { ...r.colors },
    clothes: true,
    hair: BASES[base].hair === 'long' && race === 'human' ? 'long' : r.hair,
    anim: 'Idle',
  };
}
