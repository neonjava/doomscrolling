(() => {
  const media = matchMedia('(prefers-color-scheme: dark)');
  let mode = 'system';
  try { const saved = localStorage.getItem('doomscrolling-theme'); if (['light', 'dark', 'system'].includes(saved)) mode = saved; } catch {}
  function apply() {
    const dark = mode === 'dark' || (mode === 'system' && media.matches);
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    document.querySelector('meta[name="theme-color"]')?.setAttribute('content', dark ? '#0b1018' : '#f3f6f8');
    document.querySelectorAll('.theme-picker select').forEach(select => select.value = mode);
    document.querySelectorAll('.app-screenshot').forEach(img => img.src = dark ? '/assets/app-dark.png' : '/assets/app-light.png');
  }
  apply(); media.addEventListener('change', apply);
  document.addEventListener('DOMContentLoaded', () => {
    apply();
    document.querySelectorAll('.theme-picker select').forEach(select => select.addEventListener('change', () => {
      mode = select.value; try { localStorage.setItem('doomscrolling-theme', mode); } catch {} apply();
    }));
  });
})();
