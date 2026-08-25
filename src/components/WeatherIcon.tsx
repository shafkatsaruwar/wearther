interface IconProps {
  className?: string;
}

export function WeatherIcon({
  code,
  className = "h-6 w-6",
}: IconProps & { code: string }) {
  switch (code) {
    case "clear":
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <circle cx="12" cy="12" r="4" stroke="currentColor" strokeWidth="1.5" />
          <path
            d="M12 2v2.5M12 19.5V22M2 12h2.5M19.5 12H22M4.9 4.9l1.8 1.8M17.3 17.3l1.8 1.8M4.9 19.1l1.8-1.8M17.3 6.7l1.8-1.8"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
      );
    case "rain":
    case "storm":
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M7.5 10a4.5 4.5 0 018.7-1.6A3.5 3.5 0 0117 16H7.2A3.2 3.2 0 017.5 10z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinejoin="round"
          />
          <path
            d="M9 17.5l-1 3M12.5 17.5l-1 3M16 17.5l-1 3"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
      );
    case "snow":
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M12 3v18M5.5 6.5l13 11M5.5 17.5l13-11"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
      );
    case "fog":
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M4 10h16M6 14h12M5 18h14"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
      );
    case "windy":
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M3 10h11a3 3 0 100-6 3 3 0 00-1 .17M3 14h13a3 3 0 110 6 3 3 0 01-1-.17M3 18h7"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinecap="round"
          />
        </svg>
      );
    default:
      return (
        <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
          <path
            d="M7.5 14a4.5 4.5 0 018.7-1.6A3.5 3.5 0 0117 20H7.2A3.2 3.2 0 017.5 14z"
            stroke="currentColor"
            strokeWidth="1.5"
            strokeLinejoin="round"
          />
        </svg>
      );
  }
}

export function ClothingGlyph({
  label,
  className = "h-6 w-6",
}: IconProps & { label: string }) {
  const key = label.toLowerCase();

  if (/rain|waterproof/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M6 10l6-5 6 5v8a1 1 0 01-1 1H7a1 1 0 01-1-1v-8z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
        <path
          d="M9 14l1.5 3M12 14l1 3M15 14l.5 2"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinecap="round"
        />
      </svg>
    );
  }

  if (/coat|heavy jacket/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M8 5l4 2 4-2 3 4v11H5V9l3-4z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
        <path d="M12 7v13" stroke="currentColor" strokeWidth="1.4" />
      </svg>
    );
  }

  if (/jacket|bring/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M8 6l4 1.5L16 6l3 3.5V20H5V9.5L8 6z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
        <path d="M12 7.5V20" stroke="currentColor" strokeWidth="1.4" />
      </svg>
    );
  }

  if (/sweater|scarf|glove|warm|layer/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M8 8V6a4 4 0 018 0v2l3 3v9H5v-9l3-3z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
      </svg>
    );
  }

  if (/short/.test(key) && !/sleeve/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M8 6h8l1 6H7L8 6z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
        <path d="M12 6v6" stroke="currentColor" strokeWidth="1.4" />
      </svg>
    );
  }

  if (/sneaker|shoe/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M4 15c2-1 4-3 7-3h7l2 3v2H4v-2z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
        <path
          d="M11 12c1-2 2.5-3 4-3"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinecap="round"
        />
      </svg>
    );
  }

  if (/jean|chino|pants|trouser/.test(key)) {
    return (
      <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
        <path
          d="M8 4h8l-1 16h-2.5L12 12l-.5 8H9L8 4z"
          stroke="currentColor"
          strokeWidth="1.4"
          strokeLinejoin="round"
        />
      </svg>
    );
  }

  // shirts / linen / long sleeve / short sleeve default
  return (
    <svg className={className} viewBox="0 0 24 24" fill="none" aria-hidden>
      <path
        d="M9 6l3 2 3-2 3 2.5-2 2.5V20H8V11L6 8.5 9 6z"
        stroke="currentColor"
        strokeWidth="1.4"
        strokeLinejoin="round"
      />
    </svg>
  );
}
