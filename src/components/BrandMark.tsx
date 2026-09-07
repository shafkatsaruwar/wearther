interface BrandMarkProps {
  className?: string;
}

/** Scarf-W mark: coral scarf forming a W with a sun accent on deep teal. */
export function BrandMark({ className = "h-10 w-10" }: BrandMarkProps) {
  return (
    <svg
      className={className}
      viewBox="0 0 64 64"
      fill="none"
      aria-hidden
      role="img"
    >
      <rect width="64" height="64" rx="14" fill="#0B4F49" />
      <path
        d="M10 22c3-1 5 1 7 4l5 9 6-14c1-2 3-4 5-3s3 3 4 5l5 12 4-8c2-4 5-6 8-5"
        stroke="#E56F5B"
        strokeWidth="5"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
      <path
        d="M48 22c3 1 5 4 6 8"
        stroke="#FFFDF6"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <circle cx="32" cy="28" r="3.5" fill="#E6B84D" />
    </svg>
  );
}
