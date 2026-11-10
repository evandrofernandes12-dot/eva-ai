import React, { useCallback, useEffect, useRef, useState } from 'react';
import Viewport from './components/Viewport.jsx';
import { ColorRow, Section, Segmented, Slider, Toggle } from './components/ui.jsx';
import { ANIMS } from './engine/poses.js';
import {
  BASES, CLOTH_SWATCHES, EYE_SWATCHES, HAIR_STYLES, HAIR_SWATCHES, RACES, SKIN_SWATCHES, SLIDERS,
  defaultSliders, defaultState,
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
    setState((s) => ({ ...s, race, colors: { ...r.colors }, hair: race === 'human' ? BASES[s.base].hair : r.hair }));
  };
  const setSlider = (key, v) => setState((s) => ({ ...s, sliders: { ...s.sliders, [key]: v } }));
  const setColor = (key, v) => setState((s) => ({ ...s, colors: { ...s.colors, [key]: v } }));
  const reset = () => setState((s) => ({ ...defaultState(s.base, s.race), anim: s.anim }));

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
        <div className="flex-1 space-y-3 overflow-y-auto p-4">
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
              <ColorRow label="Roupa" value={state.colors.cloth} swatches={CLOTH_SWATCHES} onChange={(v) => setColor('cloth', v)} disabled={!state.clothes} />
              <ColorRow label="Cabelo / sobrancelhas" value={state.colors.hair} swatches={HAIR_SWATCHES} onChange={(v) => setColor('hair', v)} />
            </div>
          </Section>

          <Section title="Visual">
            <div className="space-y-3">
              <div>
                <div className="mb-1.5 text-xs text-slate-300">Cabelo</div>
                <Segmented value={state.hair} onChange={(hair) => patch({ hair })} options={HAIR_STYLES} />
              </div>
              <Toggle label="Roupa (calção / top)" checked={state.clothes} onChange={(clothes) => patch({ clothes })} />
            </div>
          </Section>
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
