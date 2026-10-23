(() => {
  const button = document.querySelector('#try-swipe');
  const viewer = document.querySelector('.demo-video');
  const toast = document.querySelector('.demo-toast');
  if (!button || !viewer || !toast) return;
  let timer;
  const remind = () => {
    toast.textContent = 'You are doom scrolling'; toast.classList.add('visible');
    clearTimeout(timer); timer = setTimeout(() => toast.classList.remove('visible'), 1800);
  };
  button.addEventListener('click', remind);
  viewer.addEventListener('wheel', event => { event.preventDefault(); remind(); }, {passive:false});
  let startY;
  viewer.addEventListener('pointerdown', event => { startY = event.clientY; viewer.setPointerCapture(event.pointerId); });
  viewer.addEventListener('pointerup', event => { if (startY !== undefined && Math.abs(event.clientY - startY) > 15) remind(); startY = undefined; });
  viewer.addEventListener('pointercancel', () => { startY = undefined; });
})();
