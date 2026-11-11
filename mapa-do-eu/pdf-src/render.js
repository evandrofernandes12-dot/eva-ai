// Converte workbook.html em ../Mapa_do_Eu_Workbook.pdf
const { chromium } = require('playwright'); const path = require('path');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage();
  await p.goto('file://' + path.resolve(__dirname, 'workbook.html')); await p.waitForTimeout(400);
  await p.pdf({ path: path.resolve(__dirname, '../Mapa_do_Eu_Workbook.pdf'), preferCSSPageSize: true, printBackground: true });
  await b.close();
})();
