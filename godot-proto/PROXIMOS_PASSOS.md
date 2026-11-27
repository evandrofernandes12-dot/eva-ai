# Próximos passos (combinado com o usuário para a próxima sessão)

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
