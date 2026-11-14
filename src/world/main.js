import { ForestWorld } from './ForestWorld.js';

const msg = document.getElementById('msg');
const world = new ForestWorld(document.getElementById('world'));
window.__world = world;
world.init((m) => { msg.textContent = 'Carregando: ' + m; })
  .then(() => { msg.remove(); window.__worldReady = true; })
  .catch((e) => { console.error(e); msg.textContent = 'Erro ao carregar: ' + e.message; window.__worldError = e.message; });
