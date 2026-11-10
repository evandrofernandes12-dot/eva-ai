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

export const OUTFITS = [
  { id: 'none', label: 'Nenhuma' },
  { id: 'basic', label: 'Básica (calção / top)' },
  { id: 'tunic', label: 'Túnica e calça' },
];
export const ARMOR_SLOTS = [
  { key: 'head', label: 'Cabeça (capuz / elmo)' },
  { key: 'chest', label: 'Peitoral' },
  { key: 'shoulders', label: 'Ombreiras' },
  { key: 'arms', label: 'Braçadeiras' },
  { key: 'hands', label: 'Luvas / manoplas' },
  { key: 'legs', label: 'Pernas' },
  { key: 'feet', label: 'Botas' },
];
export const ARMOR_STYLES = [
  { id: 'none', label: 'Nenhuma' },
  { id: 'leather', label: 'Couro' },
  { id: 'plate', label: 'Placas de metal' },
];
export const MAIN_HAND = [
  { id: 'none', label: 'Vazia' },
  { id: 'knife', label: 'Faca' },
  { id: 'shortsword', label: 'Espada curta' },
  { id: 'longsword', label: 'Espada longa' },
  { id: 'spear', label: 'Lança' },
  { id: 'staff', label: 'Cajado' },
];
export const OFF_HAND = [
  { id: 'none', label: 'Vazia' },
  { id: 'shield_round', label: 'Escudo redondo' },
  { id: 'shield_kite', label: 'Escudo de cavaleiro' },
  { id: 'book', label: 'Livro' },
  { id: 'knife', label: 'Faca' },
  { id: 'bow', label: 'Arco' },
];
export const JEWELRY = [
  { key: 'ring', label: 'Anéis com gema' },
  { key: 'necklace', label: 'Cordão com pingente' },
  { key: 'bracelet', label: 'Braceletes' },
  { key: 'crown', label: 'Tiara / coroa' },
];
export const METAL_SWATCHES = ['#b8bcc4', '#8a8f98', '#c9a86a', '#5d6470', '#2f343d', '#a8573a', '#d9dce2'];
export const LEATHER_SWATCHES = ['#6b4a2f', '#3f2b1a', '#8a6a44', '#2d2a26', '#7a2a2a', '#3a4a2a'];
export const GEM_SWATCHES = ['#d62f5b', '#2f6fe0', '#2fb86a', '#8a3fe0', '#f0b429', '#31c6d6', '#f2f2f2'];
export const JEWELRY_SWATCHES = ['#d4af37', '#c0c4cc', '#b87333', '#e6c97a'];

export const emptyArmor = () => Object.fromEntries(ARMOR_SLOTS.map((a) => [a.key, 'none']));
export const emptyEquip = () => ({
  outfit: 'basic',
  armor: emptyArmor(),
  main: 'none',
  off: 'none',
  quiver: false,
  jewelry: { ring: false, necklace: false, bracelet: false, crown: false },
});

const A = (o) => ({ ...emptyArmor(), ...o });
/** Conjuntos prontos: aplicam equipamento (e, opcionalmente, cores) de uma vez. */
export const KITS = [
  { id: 'naked', label: 'Sem equip.', icon: '🚫', equip: { ...emptyEquip() } },
  {
    id: 'adventurer', label: 'Aventureiro', icon: '🧭',
    equip: { ...emptyEquip(), outfit: 'tunic', armor: A({ chest: 'leather', hands: 'leather', feet: 'leather', arms: 'leather' }), main: 'shortsword', off: 'knife', jewelry: { ring: false, necklace: true, bracelet: false, crown: false } },
    colors: { cloth: '#3d4f7a' },
  },
  {
    id: 'knight', label: 'Cavaleiro', icon: '🛡️',
    equip: { ...emptyEquip(), outfit: 'tunic', armor: A({ head: 'plate', chest: 'plate', shoulders: 'plate', arms: 'plate', hands: 'plate', legs: 'plate', feet: 'plate' }), main: 'longsword', off: 'shield_kite', jewelry: { ring: true, necklace: false, bracelet: false, crown: false } },
    colors: { cloth: '#7a1f1f', metal: '#b8bcc4' },
  },
  {
    id: 'archer', label: 'Arqueiro', icon: '🏹',
    equip: { ...emptyEquip(), outfit: 'tunic', armor: A({ head: 'leather', chest: 'leather', hands: 'leather', feet: 'leather', arms: 'leather' }), main: 'knife', off: 'bow', quiver: true, jewelry: { ring: false, necklace: false, bracelet: true, crown: false } },
    colors: { cloth: '#2f5d3a' },
  },
  {
    id: 'mage', label: 'Mago', icon: '🔮',
    equip: { ...emptyEquip(), outfit: 'tunic', armor: A({ feet: 'leather' }), main: 'staff', off: 'book', jewelry: { ring: true, necklace: true, bracelet: true, crown: true } },
    colors: { cloth: '#4b2a7a', gem: '#8a3fe0' },
  },
  {
    id: 'warlord', label: 'Senhor da guerra', icon: '⚔️',
    equip: { ...emptyEquip(), outfit: 'basic', armor: A({ shoulders: 'plate', arms: 'leather', hands: 'plate', feet: 'leather', chest: 'leather' }), main: 'spear', off: 'shield_round', jewelry: { ring: false, necklace: true, bracelet: true, crown: false } },
    colors: { cloth: '#5a3d24', metal: '#5d6470' },
  },
];

export function defaultState(base = 'male', race = 'human') {
  const r = RACES[race];
  return {
    base,
    race,
    sliders: defaultSliders(),
    colors: { ...r.colors, metal: '#b8bcc4', leather: '#6b4a2f', gem: '#d62f5b', jewelry: '#d4af37' },
    hair: BASES[base].hair === 'long' && race === 'human' ? 'long' : r.hair,
    equip: emptyEquip(),
    anim: 'Idle',
  };
}
