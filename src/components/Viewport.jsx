import React, { useEffect, useRef } from 'react';
import { CharacterEngine } from '../engine/CharacterEngine.js';

export default function Viewport({ onEngine, status }) {
  const ref = useRef(null);
  useEffect(() => {
    const engine = new CharacterEngine(ref.current);
    if (import.meta.env.DEV) window.__eva = engine;
    onEngine(engine);
    return () => { engine.dispose(); onEngine(null); };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return (
    <div className="relative h-full w-full">
      <div ref={ref} className="absolute inset-0" />
      {status.loading && (
        <div className="pointer-events-none absolute inset-0 grid place-items-center">
          <div className="rounded-xl bg-ink-800/90 px-4 py-2 text-sm text-slate-300 shadow-lg">{status.message}</div>
        </div>
      )}
      <div className="pointer-events-none absolute bottom-3 left-4 text-[11px] text-slate-500">
        Arraste para girar · Roda do mouse para zoom · Botão direito para mover
      </div>
    </div>
  );
}
