/**
 * Screen Manager for Claraverse
 * Manages Widescreen vs Normal screen modes natively
 */

let widescreenObserver: MutationObserver | null = null;
let adjustTimeout: any = null;

/**
 * Get active screen mode from localStorage
 */
export function getCurrentScreenMode(): 'wide' | 'normal' {
  const saved = localStorage.getItem('clara-screen-mode');
  return saved === 'wide' ? 'wide' : 'normal';
}

/**
 * Detect if a table is a Modelized Table by checking its headers
 */
export function isModelizedTable(table: HTMLTableElement): boolean {
  const headers = Array.from(table.querySelectorAll('th, td')).slice(0, 20).map(c => c.textContent?.toLowerCase().trim() || '');
  if (headers.length > 0) {
    const hasKeyword = headers.some(h => {
      if (h.includes('conclusion')) return true;
      if (h.includes('assertion')) return true;
      if (h.includes('ecart') || h.includes('écart')) return true;
      if (h.includes('resultat') || h.includes('résultat')) return true;
      if (/ctr\s*\d*/i.test(h)) return true;
      return false;
    });
    if (hasKeyword) return true;
  }
  // If we couldn't find specific keywords but it has a lot of columns, treat it as modelized
  const firstRowCells = table.querySelectorAll('tr:first-child th, tr:first-child td');
  if (firstRowCells.length >= 5) {
    return true; // Wide tables automatically qualify
  }
  return false;
}

let sessionMaxTargetWidth = 1200;

/**
 * Adjust all modelized tables and their containers to widescreen using CSS injection
 */
export function adjustToWideScreen(): void {
  const tables = Array.from(document.querySelectorAll('table'));
  const modelizedTables = tables.filter(isModelizedTable);

  // We don't return early anymore, we want the layout to widen even if no tables are currently visible, 
  // so that the input zone stays wide.
  
  // 1. Find the maximum needed width across all visible modelised tables
  modelizedTables.forEach(table => {
    // Get true content width by temporarily expanding the table to max-content
    const origWidth = table.style.width;
    const origMaxWidth = table.style.maxWidth;
    const origLayout = table.style.tableLayout;
    
    table.style.setProperty('width', 'max-content', 'important');
    table.style.setProperty('max-width', 'none', 'important');
    table.style.setProperty('table-layout', 'auto', 'important');
    
    const tableScrollWidth = table.scrollWidth;
    
    table.style.width = origWidth;
    table.style.maxWidth = origMaxWidth;
    table.style.tableLayout = origLayout;

    // Add extra padding (160px) to ensure columns don't wrap and there is room for shadows & padding
    const neededWidth = tableScrollWidth + 160;
    if (neededWidth > sessionMaxTargetWidth) {
      sessionMaxTargetWidth = neededWidth;
    }
  });

  // 2. Inject or update the global CSS rules
  let styleTag = document.getElementById('clara-widescreen-styles');
  if (!styleTag) {
    styleTag = document.createElement('style');
    styleTag.id = 'clara-widescreen-styles';
    document.head.appendChild(styleTag);
  }

  // Set the CSS variable on the body
  document.body.style.setProperty('--clara-target-width', `${sessionMaxTargetWidth}px`);
  
  // Activate the mode on the body
  document.body.setAttribute('data-clara-screen-mode', 'wide');

  styleTag.innerHTML = `
    /* Widen the main wrappers (chat window and input zone) */
    body[data-clara-screen-mode="wide"] [data-widescreen-target="container"] {
      max-width: var(--clara-target-width) !important;
      width: 95% !important;
      transition: max-width 0.3s ease-out;
    }

    /* Widen the individual assistant message bubbles so tables can expand */
    body[data-clara-screen-mode="wide"] [data-widescreen-target="bubble"] {
      max-width: var(--clara-target-width) !important;
      width: 95% !important;
      margin-left: auto !important;
      margin-right: auto !important;
      transition: max-width 0.3s ease-out;
    }

    /* Ensure the inner white bubble stretches to fit the new width */
    body[data-clara-screen-mode="wide"] [data-widescreen-target="bubble-inner"] {
      width: 100% !important;
    }

    /* Make ALL tables stretch nicely in wide mode to ensure uniformity */
    body[data-clara-screen-mode="wide"] .prose table {
      width: 100% !important;
      table-layout: auto !important;
    }

    /* Ensure the direct wrapper of any table also expands */
    body[data-clara-screen-mode="wide"] .prose div:has(> table) {
      max-width: none !important;
      width: 100% !important;
      overflow-x: auto !important;
    }
  `;
}

/**
 * Revert all altered styles and classes back to their originals
 */
export function restoreNormalScreen(): void {
  document.body.removeAttribute('data-clara-screen-mode');
  
  // Optionally reset the session max width so it recalculates fresh if re-enabled
  sessionMaxTargetWidth = 1200;
}

/**
 * Run adjustment debounced to avoid layout thrashing and loop feedback
 */
export function debouncedAdjust(): void {
  if (adjustTimeout) clearTimeout(adjustTimeout);
  adjustTimeout = setTimeout(() => {
    if (getCurrentScreenMode() !== 'wide') return;
    
    // Disconnect temporarily to avoid tracking our own changes
    if (widescreenObserver) {
      widescreenObserver.disconnect();
    }
    
    adjustToWideScreen();
    
    // Re-connect
    if (widescreenObserver && getCurrentScreenMode() === 'wide') {
      widescreenObserver.observe(document.body, {
        childList: true,
        subtree: true
      });
    }
  }, 50);
}

/**
 * Set active screen mode ('wide' or 'normal'), adjust layout, and toggle MutationObserver
 */
export function setScreenMode(mode: 'wide' | 'normal'): void {
  localStorage.setItem('clara-screen-mode', mode);
  
  if (mode === 'wide') {
    adjustToWideScreen();
    
    // Start observer if not already started
    if (!widescreenObserver) {
      widescreenObserver = new MutationObserver(() => {
        debouncedAdjust();
      });
    }
    widescreenObserver.disconnect();
    widescreenObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  } else {
    // Stop observer
    if (widescreenObserver) {
      widescreenObserver.disconnect();
    }
    restoreNormalScreen();
  }
  
  // Dispatch custom event to notify React components
  window.dispatchEvent(new CustomEvent('clara-screen-mode-changed', { detail: { mode } }));
}

/**
 * Boot up screen mode state on app startup
 */
export function initializeScreenMode(): void {
  const mode = getCurrentScreenMode();
  if (mode === 'wide') {
    // Run immediately
    adjustToWideScreen();
    
    // Start observer
    if (!widescreenObserver) {
      widescreenObserver = new MutationObserver(() => {
        debouncedAdjust();
      });
    }
    widescreenObserver.disconnect();
    widescreenObserver.observe(document.body, {
      childList: true,
      subtree: true
    });
  }
}
