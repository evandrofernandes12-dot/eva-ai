# Publicar o Chavinho's Kart (para você e os amigos)

Assim funciona:
- **Versão web** (`https://evandrofernandes12-dot.github.io/eva-ai/`): tablet, celular, iPhone, notebook e PC abrem pelo link, sem instalar nada. Cada envio para o repositório atualiza o jogo sozinho.
- **Servidor online** (Render, gratuito): onde os jogadores se encontram. Dorme após ~15 min sem uso; a primeira entrada demora cerca de 1 minuto.

## 1. Publicar a versão web (GitHub Pages)
1. No repositório, vá em **Settings → Pages**.
2. Em **Build and deployment → Source**, escolha **Deploy from a branch**, depois a branch **gh-pages** e a pasta **/ (root)**. Salve.
3. Faça um envio para a branch (ou clique em *Run workflow* na aba **Actions**). O workflow *Publicar versão web* gera e publica o jogo.

## 2. Criar o servidor (Render, gratuito)
1. Entre em https://render.com com sua conta do GitHub.
2. **New → Web Service** → escolha o repositório `eva-ai`.
3. Configure:
   - **Runtime:** Docker (o `Dockerfile` já está na raiz)
   - **Instance type:** Free
4. Crie. Ao terminar, o Render mostra o endereço, algo como `https://chavinhos-kart.onrender.com`.
5. Se o endereço for diferente de `wss://chavinhos-kart.onrender.com`, avise para ajustarmos `DEFAULT_SERVER_URL` em `NetworkManager.gd`.

## 3. Jogar
- Abra o link da versão web, toque em **JOGAR ONLINE → ENTRAR NO SERVIDOR**.
- Amigos fazem o mesmo. Todos marcam **PRONTO** e a corrida começa sozinha após alguns segundos.

## Atualizações
- Você envia uma mudança para o repositório → o workflow publica a versão nova.
- Quem já estava com a página aberta precisa recarregar (Ctrl+F5 no PC, ou fechar e abrir a aba no celular).
- Se a versão do jogo não bater com a do servidor, a entrada é recusada com aviso para atualizar. Ao mudar algo que afete a rede, aumente `GAME_VERSION` em `NetworkManager.gd`.

## Limitações atuais
- Batalha de Balões ainda é só offline.
- Não testado ainda no Godot real: o primeiro teste com dois aparelhos vai revelar ajustes.
