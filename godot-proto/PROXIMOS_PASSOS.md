# Próximos passos (combinado com o usuário para a próxima sessão)

> Feito na v67: itens 1, 2 e 3 (atualização dentro do jogo, opção a).

1. **Personagem inicial**: começar como aldeão ou aldeã com roupa comum de camponês (corpo UBC + `Heroi.vestir(m, "Male_Peasant"/"Female_Peasant")`), sem classe nem armadura. A classe e o herói armado ficam para depois (botão CLASSE).
2. **Abertura**:
   - A logo (`logo.png`) ocupando a tela inteira do aparelho (boot splash em tela cheia: `boot_splash/fullsize=true` ou modo de esticar que cubra a tela sem deformar; fundo combinando).
   - Uma pequena animação de abertura depois da splash (logo aparecendo/zoom, brilho, folhas ou faíscas), e em seguida a **tela de escolha: masculino ou feminino** (prévia 3D do aldeão e da aldeã, como em `scripts/escolha.gd`).
3. **Atualizações chegando sozinhas para os amigos** (sem reenviar arquivos):
   - iPhone/Web: já funciona pelo itch.io (troca o zip, o link é o mesmo).
   - Android — opções a decidir com o usuário:
     a) **Atualização dentro do jogo**: ao abrir, o jogo consulta um arquivo de versão num endereço fixo; se houver versão nova, baixa um pacote `.pck` com o conteúdo novo e carrega com `ProjectSettings.load_resource_pack()` (não precisa reinstalar; só reinstala quando mudar a engine). Precisa de um lugar para hospedar (ex.: itch.io, GitHub Releases).
     b) **App do itch.io** no Android: o amigo instala o app do itch e ele atualiza o jogo sozinho quando sai versão nova.
     c) **Google Play (teste interno/fechado)**: atualiza automático pela Play Store; precisa de conta de desenvolvedor (taxa única) e chave de assinatura própria.

## Combinado em 27/11 (depois da v69)
- **Pets lendários (nível 100, turquesa e ouro)** — escolhas do usuário (todas opção A):
  - Cavalo alado: peitoral de placas com asas gravadas + coroa de louros dourada.
  - Urso: couro reforçado com placas e pontas nos ombros + coroa de ferro de rei bárbaro.
  - Lobo: cota de malha com placa gravada com a lua + diadema lunar com pedra azul.
  - Fênix: penas de metal douradas + coroa de chamas com rubi.
  - Pets começam filhotes e sobem até o nível 100.
- **Experiência**: inimigos e missões do Rei (feito na v69). **Diamantes**: missões do Rei, chefões e venda de recursos (venda ainda falta).
- **Itens com nível 0-100** e nome a cada 10 níveis (ex.: Peitoral → Peitoral de Bronze no 10...), lendário no 100: armas, escudo, roupas, armadura, orbe, chama.
- **Aldeão até o nível 5** (só espada comum, picareta, marreta, arco e flecha comuns); no 5 escolhe guerreiro/arqueiro/mago/lanceiro **do mesmo sexo** escolhido no começo, e segue até o fim.
- **Cena do Rei**: personagem se ajoelha e abaixa a cabeça devagar, a cena muda para o Rei sentado falando a missão; ao terminar, o jogador fica livre no castelo.
- **Mochila**; **comida no armazém** (meia vida e vida cheia); lojas com diamantes: **casa do mago** (cajados, livros, capas, elmos...), **casa da artesã** (luvas, botas, capuz do arqueiro), **forja** (espadas, escudos, arcos, lanças, flechas).
- **Muro de concreto** que dá para andar por cima (faixas altas).
