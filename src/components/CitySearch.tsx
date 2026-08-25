"use client";

import { useEffect, useId, useRef, useState, useTransition } from "react";
import type { LocationResult } from "@/types/weather";

interface CitySearchProps {
  selected: LocationResult;
  onSelect: (location: LocationResult) => void;
}

export function CitySearch({ selected, onSelect }: CitySearchProps) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<LocationResult[]>([]);
  const [pending, startTransition] = useTransition();
  const rootRef = useRef<HTMLDivElement>(null);
  const listId = useId();

  useEffect(() => {
    function onDocClick(e: MouseEvent) {
      if (!rootRef.current?.contains(e.target as Node)) setOpen(false);
    }
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, []);

  useEffect(() => {
    const trimmed = query.trim();
    if (trimmed.length < 2) return;

    const controller = new AbortController();
    const timer = setTimeout(() => {
      startTransition(() => {
        void (async () => {
          try {
            const res = await fetch(
              `/api/locations?q=${encodeURIComponent(trimmed)}`,
              { signal: controller.signal },
            );
            if (!res.ok) return;
            const data = (await res.json()) as LocationResult[];
            setResults(data);
          } catch {
            /* aborted or network */
          }
        })();
      });
    }, 220);

    return () => {
      clearTimeout(timer);
      controller.abort();
    };
  }, [query]);

  function handleQueryChange(value: string) {
    setQuery(value);
    if (value.trim().length < 2) {
      setResults([]);
    }
  }

  return (
    <div ref={rootRef} className="relative w-full max-w-sm">
      <button
        type="button"
        onClick={() => setOpen((v) => !v)}
        className="group flex w-full items-center gap-2 text-left"
        aria-expanded={open}
        aria-controls={listId}
      >
        <span className="font-display text-3xl tracking-tight text-[var(--ink)] sm:text-4xl">
          {selected.name}
        </span>
        <svg
          className="mt-1 h-4 w-4 text-[var(--ink-muted)] transition-transform group-hover:text-[var(--ink)]"
          viewBox="0 0 16 16"
          fill="none"
          aria-hidden
        >
          <path
            d="M4 6l4 4 4-4"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
            strokeLinejoin="round"
          />
        </svg>
      </button>

      {open && (
        <div
          id={listId}
          className="absolute left-0 right-0 z-30 mt-3 overflow-hidden rounded-2xl border border-[var(--line)] bg-[var(--surface)] shadow-[0_20px_50px_-24px_rgba(20,24,28,0.45)] animate-fade-up"
        >
          <div className="border-b border-[var(--line)] p-3">
            <input
              autoFocus
              value={query}
              onChange={(e) => handleQueryChange(e.target.value)}
              placeholder="Search city…"
              className="w-full bg-transparent text-base text-[var(--ink)] outline-none placeholder:text-[var(--ink-faint)]"
            />
          </div>
          <ul className="max-h-64 overflow-auto py-1">
            {pending && query.trim().length >= 2 && (
              <li className="px-4 py-3 text-sm text-[var(--ink-muted)]">
                Searching…
              </li>
            )}
            {!pending && query.trim().length >= 2 && results.length === 0 && (
              <li className="px-4 py-3 text-sm text-[var(--ink-muted)]">
                No cities found
              </li>
            )}
            {results.map((loc) => (
              <li key={loc.id}>
                <button
                  type="button"
                  className="flex w-full flex-col px-4 py-2.5 text-left transition-colors hover:bg-[var(--surface-hover)]"
                  onMouseDown={(e) => {
                    // Use mousedown so selection wins over outside-click dismiss.
                    e.preventDefault();
                    onSelect(loc);
                    setOpen(false);
                    setQuery("");
                    setResults([]);
                  }}
                >
                  <span className="text-sm font-medium text-[var(--ink)]">
                    {loc.name}
                  </span>
                  <span className="text-xs text-[var(--ink-muted)]">
                    {[loc.region, loc.country].filter(Boolean).join(", ")}
                  </span>
                </button>
              </li>
            ))}
            {query.trim().length < 2 && (
              <li className="px-4 py-3 text-sm text-[var(--ink-muted)]">
                Type at least 2 letters
              </li>
            )}
          </ul>
        </div>
      )}
    </div>
  );
}
