// Minimaler JS-Einstieg für die Demo.
// Hier kannst du später Interaktionen, Analytics oder Komponenten initialisieren.

document.addEventListener('DOMContentLoaded', () => {
  // Beispiel: kleines Klick-Feedback für die Primary-CTA
  const primary = document.querySelector('.btn.primary');
  if(primary){
    primary.addEventListener('click', (e) => {
      // kleine haptische Rückmeldung im UI
      primary.animate([{ transform: 'translateY(0)' }, { transform: 'translateY(-3px)' }, { transform: 'translateY(0)' }], {
        duration: 180,
        easing: 'ease-out'
      });
    });
  }
});