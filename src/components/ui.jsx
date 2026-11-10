import React from 'react';

export function Section({ title, children, hint }) {
  return (
    <section className="rounded-2xl border border-ink-600/70 bg-ink-800/80 p-4">
      <div className="mb-3 flex items-baseline justify-between">
        <h2 className="text-[11px] font-semibold uppercase tracking-[0.14em] text-accent-soft">{title}</h2>
        {hint && <span className="text-[10px] text-slate-500">{hint}</span>}
      </div>
      {children}
    </section>
  );
}

export function Slider({ label, value, min, max, step, onChange, display, disabled }) {
  return (
    <label className={`block ${disabled ? 'opacity-40' : ''}`}>
      <div className="mb-1 flex justify-between text-xs">
        <span className="text-slate-300">{label}</span>
        <span className="tabular-nums text-slate-500">{display}</span>
      </div>
      <input
        type="range" min={min} max={max} step={step} value={value} disabled={disabled}
        onChange={(e) => onChange(parseFloat(e.target.value))}
        className="h-1.5 w-full cursor-pointer appearance-none rounded-full bg-ink-600"
      />
    </label>
  );
}

export function Segmented({ options, value, onChange, cols }) {
  return (
    <div className={`grid gap-2 ${cols || ''}`} style={{ gridTemplateColumns: `repeat(${options.length}, minmax(0, 1fr))` }}>
      {options.map((o) => (
        <button
          key={o.id} type="button" onClick={() => onChange(o.id)}
          className={`rounded-xl border px-2 py-2 text-xs font-medium transition ${
            value === o.id
              ? 'border-accent bg-accent/20 text-white shadow-[0_0_0_1px_rgba(124,92,255,.5)]'
              : 'border-ink-600 bg-ink-700/60 text-slate-400 hover:border-slate-500 hover:text-slate-200'
          }`}
        >
          {o.icon && <div className="mb-0.5 text-lg leading-none">{o.icon}</div>}
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function ColorRow({ label, value, onChange, swatches, disabled, note }) {
  return (
    <div className={disabled ? 'opacity-40' : ''}>
      <div className="mb-1.5 flex items-center justify-between text-xs">
        <span className="text-slate-300">{label}</span>
        {note && <span className="text-[10px] text-slate-500">{note}</span>}
      </div>
      <div className="flex items-center gap-1.5">
        <input type="color" value={value} disabled={disabled} onChange={(e) => onChange(e.target.value)} aria-label={label} />
        <div className="flex flex-wrap gap-1.5">
          {swatches.map((c) => (
            <button
              key={c} type="button" disabled={disabled} onClick={() => onChange(c)} aria-label={`${label} ${c}`}
              className={`h-5 w-5 rounded-full border-2 transition hover:scale-110 ${value.toLowerCase() === c.toLowerCase() ? 'border-white' : 'border-ink-600'}`}
              style={{ background: c }}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

export function Toggle({ label, checked, onChange, disabled }) {
  return (
    <label className={`flex cursor-pointer items-center justify-between text-xs text-slate-300 ${disabled ? 'opacity-40' : ''}`}>
      {label}
      <input type="checkbox" checked={checked} disabled={disabled} onChange={(e) => onChange(e.target.checked)} className="h-4 w-4 accent-[#7c5cff]" />
    </label>
  );
}
