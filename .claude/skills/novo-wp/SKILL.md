---
name: novo-wp
description: >
  Inicia e desenvolve projetos WordPress de clientes (Hello Elementor + Elementor Pro, MAMP local,
  Hostinger). Cria wordpress/ dentro da pasta do cliente com tema filho do Hello Elementor
  (a partir de templates/wordpress/hello-child), documentação e ambiente local no MAMP. Também é a
  skill pra criar uma página nova num projeto WordPress já existente: pergunta se é página por
  código (template PHP + CSS/JS próprios, com campos editáveis no painel) ou página do Elementor.
  Use quando o usuário disser "novo wp", "/novo-wp", "site em wordpress", "projeto wordpress",
  "tema filho", "página nova no wordpress", "transformar esse site em wordpress".
---

# /novo-wp — Projeto WordPress com tema filho do Hello Elementor

Ambiente padrão: VS Code + Claude Code, **MAMP** (local), WordPress + **Hello Elementor** + **Elementor Pro**, **Hostinger**, Git, SSH/SFTP.

Princípio: o visual continua sendo feito **por código**, com a mesma qualidade dos sites estáticos da Kapila, só que dentro do WordPress. O Elementor convive, mas para as páginas que fizerem sentido nele. **Nunca converter página por código em página do Elementor por conta própria.**

Publicação é outra skill: `/publicar-wp`. Esta skill nunca envia nada pra Hostinger.

## Modos

- **A. Novo projeto WordPress** → passos 1 a 6
- **B. Nova página num projeto existente** (já existe `clientes/<Nome>/wordpress/tema/`) → passo 7

---

## A. Novo projeto

### Passo 1 — Cliente

Perguntar qual cliente (listar as pastas de `clientes/`). Se for cliente novo, criar `clientes/<Nome>/` com `CLAUDE.md` e `briefing.md` no padrão da `/novo-projeto` (nome da pasta em kebab-case).

Se a pasta já tiver `wordpress/`, parar e perguntar: o projeto já existe e talvez seja o modo B.

**Não mexer em nada que já exista na pasta do cliente** (`site/`, `referencias/`, etc.). O WordPress fica só em `wordpress/`. Se o cliente já tem um site estático em `site/`, ele pode servir de **fonte** pras páginas por código (passo 7), mas não deve ser alterado.

### Passo 2 — Dados (uma pergunta só, com padrões sugeridos)

- **Slug do tema filho:** `<cliente>-child` (ex.: `bananas-child`). Só minúsculas, números e hífen
- **Nome do tema** (aparece no painel): `<Cliente> · Kapila`
- **Pasta no MAMP:** `<cliente>` → `/Applications/MAMP/htdocs/<cliente>/` → `http://localhost:8888/<cliente>/`
- **Domínio de produção:** `https://...` (pode ficar pra depois)

### Passo 3 — Estrutura

```bash
C="clientes/<Nome>/wordpress"
mkdir -p "$C"
cp -R templates/wordpress/hello-child "$C/tema"
cp templates/wordpress/projeto/README.md templates/wordpress/projeto/deploy.md "$C/"
cp -R templates/wordpress/projeto/elementor "$C/elementor"
```

Substituir os placeholders (com Edit ou sed), **só nos arquivos copiados**:

| Placeholder | Onde | Valor |
|---|---|---|
| `{{NOME_TEMA}}`, `{{CLIENTE}}` | `tema/style.css`, `README.md`, `deploy.md` | nome do tema / nome do cliente |
| `{{TEMA_SLUG}}` | `README.md`, `deploy.md` | slug |
| `{{MAMP_PASTA}}`, `{{DATA}}` | `README.md` | pasta do MAMP / data de hoje |
| `{{SITE_URL}}` | `README.md`, `deploy.md` | domínio (se ainda não souber, deixar o placeholder) |
| `{{SSH_HOST}}`, `{{WP_RAIZ}}` | `deploy.md` | **deixar como está**: são preenchidos na configuração da hospedagem (`/publicar-wp`) |

Resultado:

```
clientes/<Nome>/
  CLAUDE.md, briefing.md      (já existiam ou foram criados no passo 1)
  wordpress/
    tema/                     tema filho
      style.css               cabeçalho do tema (Template: hello-elementor)
      functions.php           só carrega os arquivos de inc/
      inc/setup.php           menus + helpers (kapila_template_atual, kapila_e_canvas)
      inc/assets.php          CSS/JS via wp_enqueue_* (por convenção de nome)
      inc/campos.php          campos editáveis no painel (sem plugin)
      inc/credito.php         "Desenvolvido por Kapila" + shortcode [kapila_credito]
      page-templates/         páginas por código (1 arquivo PHP por página)
      assets/css|js|img|fonts
    elementor/                exportações .json do Elementor Pro
    deploy.md                 config não sensível + histórico de publicação
    README.md                 documentação do projeto
```

Acrescentar ao `clientes/<Nome>/CLAUDE.md` (no fim, sem reescrever o resto):

```markdown
## WordPress

- Projeto WordPress em `wordpress/` (tema filho `<slug>` do Hello Elementor). Ver `wordpress/README.md`.
- Páginas novas: `/novo-wp` (pergunta se é por código ou Elementor). Publicar: `/publicar-wp`.
- Nunca editar o tema pai nem arquivos direto na Hostinger.
```

### Passo 4 — Ambiente local (MAMP)

Verificar o que existe e **perguntar antes de cada ação** que crie algo fora do KapilaOS:

1. **MAMP rodando?** `curl -s -o /dev/null -w '%{http_code}' http://localhost:8888/`. Se não responder, pedir pro usuário abrir o MAMP e clicar em Start (portas padrão: Apache 8888, MySQL 8889).
2. **WordPress já instalado em `/Applications/MAMP/htdocs/<pasta>/`?** (existe `wp-config.php`?)
   - Se não: oferecer baixar (`curl -L https://wordpress.org/latest.tar.gz`, extrair em `htdocs/<pasta>/`). O banco é criado pelo usuário no phpMyAdmin do MAMP (WebStart → Tools → phpMyAdmin), com o nome `wp_<cliente>`. Depois, abrir `http://localhost:8888/<pasta>/` e seguir o instalador (banco `wp_<cliente>`, usuário `root`, senha `root`, servidor `localhost:8889`). Essas credenciais são do MAMP local e ficam só no `wp-config.php` do htdocs, nunca no KapilaOS.
   - Sugerir no `wp-config.php` local: `define( 'WP_ENVIRONMENT_TYPE', 'local' );` e `define( 'WP_DEBUG', true );`.
3. **Hello Elementor:** instalar pelo painel (Aparência → Temas → Adicionar → "Hello Elementor"). **Nunca editar os arquivos dele.**
4. **Elementor e Elementor Pro:** o usuário instala e licencia manualmente. Não instalar automaticamente.
5. **Ligar o tema filho** (com autorização), por link simbólico:
   ```bash
   ln -s "$(pwd)/clientes/<Nome>/wordpress/tema" "/Applications/MAMP/htdocs/<pasta>/wp-content/themes/<slug>"
   ```
   Depois: Aparência → Temas → ativar `<Nome do tema>`. Se o CSS der 404, o Apache do MAMP não está seguindo links simbólicos: copiar a pasta em vez de linkar e avisar.

### Passo 5 — Documentação

Completar o `wordpress/README.md` (resumo, tabela de páginas). O `deploy.md` fica com os placeholders de hospedagem até o `/publicar-wp` configurar.

### Passo 6 — Resumo

```
✓ clientes/<Nome>/wordpress/ criado (tema filho <slug>)
✓ CLAUDE.md do cliente com a seção WordPress
Local: http://localhost:8888/<pasta>/  (ou: pendente — <o que falta>)
Próximo: criar a primeira página (/novo-wp → nova página) ou configurar a hospedagem (/publicar-wp)
```

---

## B. Nova página

### Passo 7.1 — Perguntar o tipo

> "Essa página vai ser **por código** (HTML/CSS/JS/PHP próprios, visual 100% nosso) ou **no Elementor** (montada no editor visual, mais fácil pro cliente mexer)?"

Se o usuário não tiver preferência, recomendar **código** para landing pages, páginas de venda e páginas com animação ou design próprio, e **Elementor** para páginas simples que o cliente vai editar com frequência.

### Passo 7.2a — Página por código

1. **Layout:**
   - `canvas`: HTML completo, sem cabeçalho/rodapé do site (padrão para LP e página de links). Modelo: `page-templates/pagina-codigo.php`
   - `site`: entre o cabeçalho e o rodapé do Theme Builder do Elementor Pro. Modelo: `page-templates/pagina-codigo-header.php`
2. **Criar os arquivos** (`<nome>` em kebab-case, ex.: `links`):
   - `tema/page-templates/<nome>.php`: copiar o modelo e trocar `Template Name: <Cliente> · <Página>` e `Kapila Layout`
   - `tema/assets/css/<nome>.css` e, se precisar, `tema/assets/js/<nome>.js`. São carregados sozinhos pelo `inc/assets.php` (não registrar à mão)
   - Imagens em `tema/assets/img/`, referenciadas no PHP com `kapila_asset_url( 'img/arquivo.webp' )` e no CSS com caminho relativo (`../img/arquivo.webp`)
   - Fontes: `KAPILA_FONTES_URL` em `inc/assets.php` (Google Fonts) ou arquivos em `assets/fonts/`
   - Os tokens visuais (cores, fontes) vão em `assets/css/base.css`
3. **Design:** mesmo processo e padrão de qualidade dos sites estáticos. Seguir a identidade do cliente (`clientes/<Nome>/CLAUDE.md`, `briefing.md`, `referencias/`). Para páginas da própria Kapila, seguir `identidade/design-guide.md`. Se o cliente já tem a página pronta em `site/`, **portar** de lá: o HTML vai para o template, o CSS e o JS para `assets/`, e os caminhos viram `kapila_asset_url()`. Não alterar o original. As skills existentes (`/carrossel`, `/seo` etc.) continuam iguais e podem ser chamadas normalmente quando o trabalho pedir.
4. **Regras de WordPress:**
   - Sempre manter `wp_head()`, `wp_body_open()`, `wp_footer()`, `language_attributes()`, `body_class()` (no canvas) ou `get_header()`/`get_footer()` (no site)
   - Nenhum `<link>`/`<script>` escrito à mão para arquivos do tema: tudo via `inc/assets.php`
   - Escapar toda saída: `esc_html()`, `esc_attr()`, `esc_url()`; para HTML vindo do painel, `wp_kses_post()`
   - Links internos com `home_url( '/caminho/' )`; nada de domínio fixo no código
   - Funções novas com prefixo `kapila_`; código PHP compartilhado em `inc/`
   - Canvas leva o crédito: `<?php echo kapila_credito_html(); ?>` no rodapé
5. **Campos editáveis (quando fizer sentido):** se o cliente vai trocar textos, imagens ou links, declarar os campos em `inc/campos.php` → `kapila_campos_definicoes()`, na chave `'<nome>'`, com os tipos `texto`, `textarea`, `url` e `imagem`. No template, usar `kapila_campo( 'chave', 'padrão' )` e `kapila_imagem_url( 'chave', 'url padrão' )`. O padrão é sempre o texto final da página, assim ela nunca fica em branco. Para listas repetidas (ex.: vários links), usar campos numerados (`link_1_texto`, `link_1_url`…) só até onde o cliente realmente vai editar. **Sem ACF nem outro plugin**, a menos que o usuário peça.
6. **Validar:** `/Applications/MAMP/bin/php/php8.3.30/bin/php -l <arquivo>` (ou o PHP 8 mais novo do MAMP) em cada PHP criado ou alterado.
7. **Criar a página no painel** (instruir o usuário): Páginas → Adicionar → título e endereço (slug) → Modelo: "<Cliente> · <Página>" → Publicar. Os campos editáveis aparecem depois de salvar com o modelo. **Não clicar em "Editar com Elementor" nessas páginas.**
8. **Conferir no MAMP:** `curl -s -o /dev/null -w '%{http_code}' http://localhost:8888/<pasta>/<slug>/` e pedir pro usuário olhar no navegador.

### Passo 7.2b — Página do Elementor

1. O usuário cria no painel: Páginas → Adicionar → "Editar com Elementor" (modelo "Elementor Canvas" ou "Elementor Largura Total", conforme o caso).
2. Ajudar com estrutura, textos e CSS (o CSS global pequeno vai no `tema/style.css`; o de um widget, no campo "CSS personalizado" do Elementor Pro).
3. Se quiser versionar: exportar o template para `wordpress/elementor/` (instruções no README de lá).
4. O conteúdo fica no banco: subir pra produção é exportar/importar o template ou montar direto no site no ar. Não vai pelo `/publicar-wp`.

### Passo 7.3 — Registrar

Adicionar a página na tabela "Páginas" do `wordpress/README.md` (página, tipo, template, observações).

---

## Nunca

- Editar o tema pai `hello-elementor`
- Converter página por código em Elementor (ou o contrário) sem pedido explícito
- Instalar plugin, Elementor Pro ou qualquer dependência sem perguntar
- Colocar senha, token ou chave em qualquer arquivo do projeto
- Publicar na Hostinger (isso é o `/publicar-wp`, sempre com confirmação)
- Sincronizar banco local com produção
