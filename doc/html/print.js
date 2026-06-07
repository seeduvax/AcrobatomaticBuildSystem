const fs = require("node:fs");
const { chromium } = require('playwright-core');

(async () => {
  // Lancer le navigateu
  const browser = await chromium.launch({ 
    headless: true,
    executablePath: '{PATH_BROWSER}' // Exemple : '/usr/bin/google-chrome'
 });

  // Ouvrir une nouvelle page
  const page = await browser.newPage();

  // Naviguer vers l'URL de ton choix
  await page.goto('{PATH_HTML}', {
    waitUntil: 'networkidle' // Attendre que le réseau soit inactif
  });

  const element = await page.locator('.page').first();
  const dimensions = await element.evaluate((el) => {
    return {
      offsetWidth: el.offsetWidth,       // Largeur totale (inclut bordures/padding)
      offsetHeight: el.offsetHeight,     // Hauteur totale
    };
  });

  let content = await page.content();
  fs.writeFileSync("{EXPORT}", content);

  // Générer le PDF
  await page.pdf({
    path: '{OUTPUT}', // Chemin où enregistrer le PDF
    width: dimensions.offsetWidth,
    height: dimensions.offsetHeight,
    printBackground: true, // Inclure les arrière-plans
    displayHeaderFooter: false, // Désactive l'en-tête et le pied de page
    preferCSSPageSize: true,
    margin: { // Marges (en pouces ou 'none')
      top: 0,
      right: 0,
      bottom: 0,
      left: 0
    }
  });

  // Fermer le navigateur
  await browser.close();
})();