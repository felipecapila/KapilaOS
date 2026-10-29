# KapilaOS — Sistema operacional do negócio

Sua empresa roda em cima desse arquivo. Aqui ficam as regras de operação
do KapilaOS — como o Claude lê o contexto, aprende com correções, mantém
tudo atualizado e cria skills novas conforme a operação evolui.

Esse arquivo é editável. Quando o `/instalar` rodar, ele complementa o
final dessa página com as regras específicas do seu negócio.

---

## Contexto do negócio

No início de toda conversa, ler os seguintes arquivos (quando existirem
e estiverem preenchidos):

1. `_memoria/empresa.md` — quem é o usuário, o que faz, como funciona o negócio
2. `_memoria/preferencias.md` — tom de voz, estilo de escrita, o que evitar
3. `_memoria/estrategia.md` — foco atual, prioridades, prazos

Usar essas informações como base pra qualquer resposta ou decisão. Ao
sugerir prioridades, formatos ou abordagens, considerar o foco atual
descrito em `estrategia.md`.

Pra qualquer tarefa visual (carrossel, post, landing page), consultar
`identidade/design-guide.md` como referência de estilo.

Não é necessário listar o que foi lido nem confirmar a leitura. Apenas
usar o contexto naturalmente.

---

## Fluxo de trabalho

Antes de executar qualquer tarefa, verificar se existe skill relevante
em `.claude/skills/`. Se encontrar, seguir as instruções da skill. Se
não encontrar, executar a tarefa normalmente.

Ao concluir uma tarefa que não tinha skill mas parece repetível (o
usuário provavelmente vai pedir de novo no futuro), perguntar:

> "Isso pode virar uma skill pra próxima vez. Quer que eu crie?"

Não perguntar pra tarefas pontuais ou perguntas simples. Só quando o
padrão de repetição for claro.

---

## Aprender com correções

Quando o usuário corrigir algo, melhorar uma resposta ou dar uma
instrução que parece permanente (frases como "na verdade é assim", "não
faça mais isso", "prefiro assim", "sempre que...", "evita...", "da
próxima vez..."), perguntar:

> "Quer que eu salve isso pra não precisar repetir?"

Se sim, identificar onde faz mais sentido salvar:

- **Sobre o negócio** (clientes, serviços, mercado) → `_memoria/empresa.md`
- **Sobre preferências e estilo** (tom de voz, formato, o que evitar) → `_memoria/preferencias.md`
- **Sobre prioridades e foco** (projetos, metas, prazos) → `_memoria/estrategia.md`
- **Regra de comportamento nessa pasta** → próprio `CLAUDE.md`

Salvar com uma linha nova clara, sem reformatar o arquivo inteiro.
Confirmar mostrando a linha adicionada.

Não perguntar se a correção for óbvia de contexto imediato (ex: "na
verdade o arquivo se chama X"). Só perguntar quando a informação tiver
valor duradouro.

---

## Manter contexto atualizado

Ao terminar uma tarefa que mudou algo relevante (cliente novo, skill
nova, mudança de foco, processo novo, ferramenta instalada, estrutura
alterada), perguntar:

> "Isso mudou algo no teu contexto. Quer que eu atualize a memória?"

Se sim, identificar o que atualizar:

- **Cliente, serviço, ferramenta, equipe** → `_memoria/empresa.md`
- **Mudança de prioridade ou foco** → `_memoria/estrategia.md`
- **Tom ou estilo** → `_memoria/preferencias.md`
- **Pasta, regra de organização, skill criada** → `CLAUDE.md`
- **Visual (cores, fontes, logo)** → `identidade/design-guide.md`

Mostrar o que vai mudar antes de salvar. Não reformatar o arquivo
inteiro, só adicionar ou editar a linha relevante.

**Quando NÃO perguntar:**
- Tarefas pontuais sem impacto no contexto (escrever um email avulso, criar um post)
- Perguntas simples ou conversas sem ação
- Mudanças já salvas pelo bloco "Aprender com correções"

**Dica:** rode `/atualizar` pra uma varredura completa quando houver dúvida.

---

## Padrões de sites e páginas

Valem pra todo site, landing page ou página de cliente, novo ou em atualização.

**Organização**

- Cliente novo → `clientes/<Nome>/` com `briefing.md`. Funil em `clientes/<Nome>/funil.md`, páginas em `clientes/<Nome>/paginas/`
- Site estático (HTML/CSS/JS) fica em `clientes/<Nome>/site/`
- Site em WordPress → `/novo-wp` (projeto em `clientes/<Nome>/wordpress/`, tema filho do Hello Elementor, MAMP local). Página nova num projeto WordPress também é `/novo-wp`: perguntar se é por código ou Elementor, e nunca converter uma na outra sem pedido
- Publicar/atualizar WordPress na Hostinger → `/publicar-wp`, sempre com plano + confirmação explícita. Nunca publicar só porque algo foi salvo; nunca sincronizar banco automaticamente
- Demo de prospecção → usar logo, fotos e dados reais do próprio cliente (site antigo/Instagram em `referencias/`). Tudo que for provisório fica marcado `PLACEHOLDER` no código e listado no `briefing.md` como pendente

**Rodapé e endereços**

- Todo site leva no rodapé o crédito "Desenvolvido por Kapila", com "Kapila" linkando pra https://felipecapila.com.br. Ao atualizar projeto que ainda não tem, adicionar
- Site estático nunca mostra `.html` (nem `.php`) no endereço: links internos, canonical e sitemap usam `dominio/pagina`, e o `.htaccess` serve o arquivo por dentro e redireciona (301) quem acessar com a extensão
- Ao trocar uma imagem já publicada (logo, favicon, og-image, foto), salvar com **nome de arquivo novo** (ou `?v=N`). Imagem fica em cache por 1 ano no navegador e na CDN da Hostinger, e com o mesmo nome a antiga continua aparecendo

**Scroll suave (Lenis)**

- Todo site tem Lenis: `lenis@1.3.4` via jsDelivr, `duration: 1.15`, easing expo, âncoras internas com `lenis.scrollTo` descontando o header, `lenis.stop()/start()` ao abrir menu/modal, desligado com `prefers-reduced-motion`
- `data-lenis-prevent` só em área com rolagem **vertical** própria (menu, modal, lista longa). Área que só rola pro lado (tabela, abas, carrossel, Kanban) usa `data-lenis-prevent-horizontal`, senão a roda do mouse trava na página. Testar com a roda do mouse em cima da área

**Texto**

- Nunca usar travessão (—), meia-risca (–) ou hífen solto ( - ) em títulos e textos de cliente: cliente lê como texto de IA. Trocar por ponto, vírgula ou dois-pontos. Evitar também hífen em título ("liberá-lo" → reescrever) e traço decorativo antes de sobretítulo. Revisar com busca por "—", "–" e " - " antes de entregar

**Design sem cara de IA**

- Evitar: serifa editorial com palavra em itálico colorido no título, sobretítulo em caixa alta ou selo em pílula acima de título, numeração 01/02/03 em toda lista, grade de células com borda fina e cantos retos, brilho em volta de foto, selo inclinado, ícone dentro de quadrado colorido, o mesmo esquema "título gigante + texto cinza + link" em toda seção
- Preferir: sans moderna (peso 700, tracking negativo), destaque só por cor, cantos arredondados (20 a 40px) com sombra suave, seções escuras como painéis arredondados com margem, foto real sangrada, layout variando entre seções
- Botões do topo sempre acima da dobra numa tela de ~1450x700
- Cards curtos (contatos, diferenciais, itens) no desktop ficam lado a lado numa faixa de 3 ou 4 colunas, nunca empilhados numa coluna estreita. Tablet 2 colunas, celular empilha
- Imagem com `width`/`height` no HTML precisa de `height: auto` no CSS

**HTML que vira PDF (e-book, apresentação)**

- `box-shadow` com blur vira retângulo preto no PDF do Chrome. Fazer a sombra com uma camada própria com `filter: blur()` e deixar `box-shadow` só em `@media screen`
- Textura de papel em filtro SVG deixa o PDF enorme (40 MB+) e muda no Preview do Mac. Usar PNG de textura com transparência, sem `mix-blend-mode`
- Sempre gerar um PDF de teste e olhar as páginas antes de entregar

---

## Criação de skills

Quando o usuário pedir skill nova:

1. Verificar se existe template relevante em `templates/skills/`. Se
   existir, usar como base e adaptar pro contexto
2. Perguntar se é específica desse projeto ou útil em qualquer:
   - Específica → `.claude/skills/nome-da-skill/SKILL.md` (local)
   - Universal → `~/.claude/skills/nome-da-skill/SKILL.md` (global)
3. Ler `_memoria/empresa.md` e `_memoria/preferencias.md` pra calibrar
   o conteúdo da skill ao contexto do negócio
4. Se a skill precisar de arquivos de apoio (templates, exemplos),
   criar dentro da pasta da skill
5. Seguir o fluxo da skill-creator nativa do Claude Code
