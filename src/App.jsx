import React, { useCallback, useEffect, useRef, useState } from 'react';
import Viewport from './components/Viewport.jsx';
import { ColorRow, Section, Segmented, Select, Slider, Tabs, Toggle } from './components/ui.jsx';
import { ANIMS } from './engine/poses.js';
import {
  ARMOR_SLOTS, ARMOR_STYLES, BASES, CLOTH_SWATCHES, EYE_SWATCHES, GEM_SWATCHES, HAIR_STYLES, HAIR_SWATCHES,
  JEWELRY, JEWELRY_SWATCHES, KITS, LEATHER_SWATCHES, MAIN_HAND, METAL_SWATCHES, OFF_HAND, OUTFITS, RACES,
  SKIN_SWATCHES, SLIDERS, defaultSliders, defaultState, emptyEquip,
} from './engine/presets.js';

function download(blob, name) {
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url; a.download = name;
  document.body.appendChild(a); a.click(); a.remove();
  setTimeout(() => URL.revokeObjectURL(url), 2000);
}

export default function App() {
  const [engine, setEngine] = useState(null);
  const [state, setState] = useState(() => defaultState());
  const [ready, setReady] = useState(false);
  const [status, setStatus] = useState({ loading: true, message: 'Iniciando…' });
  const [exporting, setExporting] = useState(null);
  const [tab, setTab] = useState('char');
  const [error, setError] = useState('');
  const stateRef = useRef(state);
  stateRef.current = state;

  const patch = useCallback((p) => setState((s) => ({ ...s, ...p })), []);

  // carrega o modelo base quando a engine existe ou o sexo muda
  useEffect(() => {
    if (!engine) return;
    let cancelled = false;
    setReady(false);
    setStatus({ loading: true, message: 'Carregando modelo 3D…' });
    engine.loadBase(state.base)
      .then(() => {
        if (cancelled) return;
        engine.apply(stateRef.current);
        setReady(true);
        setStatus({ loading: false, message: '' });
      })
      .catch((e) => { console.error(e); setError(`Falha ao carregar o modelo: ${e.message}`); setStatus({ loading: false, message: '' }); });
    return () => { cancelled = true; };
  }, [engine, state.base]);

  useEffect(() => { if (engine && ready) engine.apply(state); }, [engine, ready, state]);

  const setRace = (race) => {
    const r = RACES[race];
    setState((s) => ({ ...s, race, colors: { ...s.colors, ...r.colors }, hair: race === 'human' ? BASES[s.base].hair : r.hair }));
  };
  const setSlider = (key, v) => setState((s) => ({ ...s, sliders: { ...s.sliders, [key]: v } }));
  const setColor = (key, v) => setState((s) => ({ ...s, colors: { ...s.colors, [key]: v } }));
  const reset = () => setState((s) => ({ ...defaultState(s.base, s.race), anim: s.anim }));
  const setEquip = (p) => setState((s) => ({ ...s, equip: { ...s.equip, ...p } }));
  const setArmor = (slot, v) => setState((s) => ({ ...s, equip: { ...s.equip, armor: { ...s.equip.armor, [slot]: v } } }));
  const setJewel = (k, v) => setState((s) => ({ ...s, equip: { ...s.equip, jewelry: { ...s.equip.jewelry, [k]: v } } }));
  const applyKit = (kit) => setState((s) => ({
    ...s,
    equip: JSON.parse(JSON.stringify(kit.equip)),
    colors: { ...s.colors, ...(kit.colors || {}) },
  }));

  const doExport = async (format) => {
    if (!engine) return;
    setExporting(format); setError('');
    try {
      const blob = await engine.export(format);
      download(blob, `personagem_${state.race}_${state.base}.${format}`);
    } catch (e) {
      console.error(e); setError(`Falha na exportação: ${e.message}`);
    } finally { setExporting(null); }
  };

  return (
    <div className="flex h-full w-full">
      <main className="relative min-w-0 flex-1">
        <Viewport onEngine={setEngine} status={status} />
        <div className="pointer-events-none absolute left-4 top-3">
          <div className="text-sm font-semibold tracking-wide text-white">Eva · Criador 3D</div>
          <div className="text-[11px] text-slate-500">{RACES[state.race].label} · {BASES[state.base].label}</div>
          <a href="world.html" className="pointer-events-auto mt-1 inline-block text-[11px] text-accent hover:underline">🌲 Ver a floresta e a aldeia →</a>
        </div>
        <div className="absolute bottom-4 left-1/2 flex -translate-x-1/2 gap-2 rounded-2xl border border-ink-600/70 bg-ink-800/85 p-1.5 backdrop-blur">
          {ANIMS.map((a) => (
            <button
              key={a.id} type="button" onClick={() => patch({ anim: a.id })}
              className={`rounded-xl px-4 py-2 text-xs font-medium transition ${
                state.anim === a.id ? 'bg-accent text-white' : 'text-slate-400 hover:bg-ink-600 hover:text-white'
              }`}
            >
              <span className="mr-1">{a.icon}</span>{a.label}
            </button>
          ))}
        </div>
      </main>

      <aside className="flex h-full w-[360px] shrink-0 flex-col border-l border-ink-600/70 bg-ink-900">
        <div className="px-4 pt-4">
          <Tabs value={tab} onChange={setTab} tabs={[{ id: 'char', label: 'Personagem' }, { id: 'equip', label: 'Equipamento' }]} />
        </div>
        <div className="flex-1 space-y-3 overflow-y-auto p-4">
          {tab === 'char' && (
            <>
              <Section title="Corpo base">
                <Segmented
                  value={state.base}
                  onChange={(base) => setState((s) => ({ ...s, base, hair: s.race === 'human' ? BASES[base].hair : s.hair }))}
                  options={Object.entries(BASES).map(([id, b]) => ({ id, label: b.label }))}
                />
              </Section>

              <Section title="Raça / Monstro">
                <Segmented
                  value={state.race} onChange={setRace}
                  options={Object.entries(RACES).map(([id, r]) => ({ id, label: r.label, icon: r.icon }))}
                />
              </Section>

              <Section title="Proporções" hint="escala de ossos">
                <div className="space-y-3">
                  {SLIDERS.map((s) => (
                    <Slider
                      key={s.key} label={s.label} min={s.min} max={s.max} step={s.step}
                      value={state.sliders[s.key]} display={s.fmt(state.sliders[s.key], RACES[state.race].mods)}
                      onChange={(v) => setSlider(s.key, v)}
                    />
                  ))}
                  <button
                    type="button" onClick={() => patch({ sliders: defaultSliders() })}
                    className="text-[11px] text-slate-500 underline-offset-2 hover:text-slate-300 hover:underline"
                  >Restaurar proporções</button>
                </div>
              </Section>

              <Section title="Cores">
                <div className="space-y-3.5">
                  <ColorRow label={state.race === 'werewolf' ? 'Pelagem / pele' : 'Pele'} value={state.colors.skin} swatches={SKIN_SWATCHES} onChange={(v) => setColor('skin', v)} />
                  <ColorRow label="Olhos" value={state.colors.eyes} swatches={EYE_SWATCHES} onChange={(v) => setColor('eyes', v)} />
                  <ColorRow label="Cabelo / sobrancelhas" value={state.colors.hair} swatches={HAIR_SWATCHES} onChange={(v) => setColor('hair', v)} />
                </div>
              </Section>

              <Section title="Cabelo">
                <Segmented value={state.hair} onChange={(hair) => patch({ hair })} options={HAIR_STYLES} />
              </Section>
            </>
          )}

          {tab === 'equip' && (
            <>
              <Section title="Conjuntos prontos">
                <div className="grid grid-cols-3 gap-2">
                  {KITS.map((k) => (
                    <button
                      key={k.id} type="button" onClick={() => applyKit(k)}
                      className="rounded-xl border border-ink-600 bg-ink-700/60 px-1 py-2 text-[11px] font-medium text-slate-300 transition hover:border-accent hover:text-white"
                    >
                      <div className="mb-0.5 text-lg leading-none">{k.icon}</div>{k.label}
                    </button>
                  ))}
                </div>
              </Section>

              <Section title="Roupas">
                <div className="space-y-3">
                  <Select label="Conjunto" value={state.equip.outfit} options={OUTFITS} onChange={(outfit) => setEquip({ outfit })} />
                  <ColorRow label="Cor do tecido" value={state.colors.cloth} swatches={CLOTH_SWATCHES} onChange={(v) => setColor('cloth', v)} disabled={state.equip.outfit === 'none'} />
                </div>
              </Section>

              <Section title="Armadura" hint="peça por peça">
                <div className="space-y-2.5">
                  {ARMOR_SLOTS.map((a) => (
                    <Select key={a.key} label={a.label} value={state.equip.armor[a.key]} options={ARMOR_STYLES} onChange={(v) => setArmor(a.key, v)} />
                  ))}
                  <button
                    type="button" onClick={() => setEquip({ armor: emptyEquip().armor })}
                    className="text-[11px] text-slate-500 underline-offset-2 hover:text-slate-300 hover:underline"
                  >Remover armadura</button>
                </div>
              </Section>

              <Section title="Armas e escudos">
                <div className="space-y-2.5">
                  <Select label="Mão direita" value={state.equip.main} options={MAIN_HAND} onChange={(main) => setEquip({ main })} />
                  <Select label="Mão esquerda" value={state.equip.off} options={OFF_HAND} onChange={(off) => setEquip({ off })} />
                  <Toggle label="Aljava com flechas (automática com arco)" checked={state.equip.quiver || state.equip.off === 'bow'} disabled={state.equip.off === 'bow'} onChange={(quiver) => setEquip({ quiver })} />
                </div>
              </Section>

              <Section title="Joias e artefatos">
                <div className="space-y-2.5">
                  {JEWELRY.map((j) => (
                    <Toggle key={j.key} label={j.label} checked={!!state.equip.jewelry[j.key]} onChange={(v) => setJewel(j.key, v)} />
                  ))}
                </div>
              </Section>

              <Section title="Cores do equipamento">
                <div className="space-y-3.5">
                  <ColorRow label="Metal (armadura e lâminas)" value={state.colors.metal} swatches={METAL_SWATCHES} onChange={(v) => setColor('metal', v)} />
                  <ColorRow label="Couro" value={state.colors.leather} swatches={LEATHER_SWATCHES} onChange={(v) => setColor('leather', v)} />
                  <ColorRow label="Gemas" value={state.colors.gem} swatches={GEM_SWATCHES} onChange={(v) => setColor('gem', v)} />
                  <ColorRow label="Joias (ouro / prata)" value={state.colors.jewelry} swatches={JEWELRY_SWATCHES} onChange={(v) => setColor('jewelry', v)} />
                </div>
              </Section>
            </>
          )}
        </div>

        <div className="space-y-2 border-t border-ink-600/70 bg-ink-800 p-4">
          {error && <div className="rounded-lg bg-red-950/60 px-3 py-2 text-xs text-red-300">{error}</div>}
          <div className="grid grid-cols-2 gap-2">
            <button
              type="button" disabled={!ready || !!exporting} onClick={() => doExport('glb')}
              className="rounded-xl bg-accent px-3 py-3 text-sm font-semibold text-white transition hover:brightness-110 disabled:opacity-40"
            >{exporting === 'glb' ? 'Exportando…' : 'Exportar .GLB'}</button>
            <button
              type="button" disabled={!ready || !!exporting} onClick={() => doExport('gltf')}
              className="rounded-xl border border-accent/60 px-3 py-3 text-sm font-semibold text-accent-soft transition hover:bg-accent/10 disabled:opacity-40"
            >{exporting === 'gltf' ? 'Exportando…' : 'Exportar .GLTF'}</button>
          </div>
          <button type="button" onClick={reset} className="w-full text-[11px] text-slate-500 hover:text-slate-300">Redefinir personagem</button>
        </div>
      </aside>
    </div>
  );
}
