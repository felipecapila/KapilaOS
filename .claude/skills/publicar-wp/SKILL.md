---
name: publicar-wp
description: >
  Publica e atualiza o tema filho de projetos WordPress de clientes na Hostinger, via SSH + rsync
  (ou SFTP como alternativa), com comparação local × servidor, lista do que vai ser enviado,
  substituído ou excluído, confirmação obrigatória, backup antes de enviar, verificação do site
  depois e histórico no deploy.md. Também guia a primeira publicação (WordPress na hospedagem,
  migração inicial do banco, URLs) e a configuração do acesso SSH. Use quando o usuário disser
  "publicar wp", "/publicar-wp", "subir o tema", "atualizar o site wordpress", "publicar na
  hostinger" num projeto com pasta wordpress/, ou "configurar ssh da hostinger".
---

# /publicar-wp — Publicar tema filho na Hostinger

Motor: `scripts/publicar-wp.sh` (compartilhado, serve pra todos os clientes). Configuração não sensível: `clientes/<Nome>/wordpress/deploy.md`.

## Regras que não mudam

1. **Nunca publicar sem confirmação explícita** do usuário nesta conversa, dada depois de ele ver o plano. Salvar arquivo, terminar página ou "ficou bom" **não** é autorização. Sempre perguntar com `AskUserQuestion`.
2. Só o **tema filho** (`wp-content/themes/<slug>`) sobe. Nunca core, plugins, uploads, `wp-config.php` ou tema pai.
3. **Nada é excluído no servidor** sem autorização específica para a exclusão (flag `--excluir`), separada da autorização de envio.
4. **Banco de dados nunca é sincronizado** automaticamente, em nenhuma direção.
5. Nenhuma operação destrutiva no servidor (sem `rm -rf`, sem sobrescrever WordPress existente). Comandos no servidor, só de leitura, fora o envio aprovado.
6. Senhas, tokens e chaves nunca vão para arquivos do projeto nem aparecem na conversa. A chave privada nunca é lida nem exibida, só a pública (`~/.ssh/id_ed25519.pub`).

## Passo 0 — Projeto

Identificar `clientes/<Nome>/wordpress/`. Se não existir, o projeto ainda não foi criado: usar `/novo-wp`.

Ler o `deploy.md`. Se o bloco `config` ainda tiver `{{SSH_HOST}}`/`{{WP_RAIZ}}`, ir para **Configuração do acesso**.

## Configuração do acesso (uma vez por cliente)

1. **hPanel → Avançado → Acesso SSH:** ativar o SSH e anotar IP, porta (65002) e usuário (`u123…`). O SSH existe nos planos Premium e superiores. Se o plano não tiver SSH, o SFTP usa a mesma porta e o mesmo usuário (ver alternativa abaixo).
2. **Chave:** a chave do Mac é `~/.ssh/id_ed25519` (ed25519, sem senha). Mostrar só a **pública** (`cat ~/.ssh/id_ed25519.pub`) para o usuário colar em hPanel → Acesso SSH → Chaves SSH. Não gerar chave nova sem necessidade.
3. **`~/.ssh/config`:** propor o bloco abaixo e só gravar com autorização. **Acrescentar** ao arquivo, nunca reescrever:
   ```
   Host hostinger-<cliente>
     HostName <ip>
     Port 65002
     User <usuário>
     IdentityFile ~/.ssh/id_ed25519
     IdentitiesOnly yes
   ```
4. **Testar:** `ssh -o BatchMode=yes hostinger-<cliente> 'echo ok'`. Na primeira conexão, o SSH pede pra confirmar a impressão digital do servidor: pedir pro usuário rodar `ssh hostinger-<cliente>` uma vez no terminal e aceitar.
5. **Preencher o `deploy.md`:**
   - `ssh_host: hostinger-<cliente>`
   - `wp_raiz`: geralmente `domains/<dominio>/public_html` (confirmar com `ssh hostinger-<cliente> 'ls domains'`)
   - `site_url`
   - `metodo: rsync`. Se o `verificar` disser que não há rsync no servidor, usar `metodo: sftp`
6. Rodar o **Passo 1**.

**Alternativa SFTP:** com `metodo: sftp`, o script usa `sftp` em lote com a mesma chave e o mesmo `~/.ssh/config` e baixa a cópia do servidor pra comparar. Se a Hostinger só aceitar senha (sem chave), o script não consegue rodar sozinho. Nesse caso, gerar o plano normalmente, e o envio é feito pelo usuário com o lote gerado (`sftp -b <lote> hostinger-<cliente>`, digitando a senha no próprio terminal) ou num cliente SFTP, sempre só com os arquivos do plano.

## Passo 1 — Verificar (só leitura)

```bash
scripts/publicar-wp.sh verificar "clientes/<Nome>/wordpress"
```

Mostra: tema local válido e PHP sem erro de sintaxe; conexão; WordPress, Hello Elementor, Elementor e Elementor Pro no servidor; versões; se o tema filho já existe (**primeira publicação** ou **atualização**); rsync e WP-CLI no servidor; `siteurl` e tema ativo (se houver WP-CLI); resposta HTTP do site.

Resumir pro usuário em linguagem simples. Se faltar WordPress ou Hello Elementor no servidor, **parar**: a instalação é feita pelo usuário no hPanel (Auto Installer do WordPress) e pelo painel do WordPress (tema e plugins). Nunca instalar por cima de um WordPress existente.

## Passo 2A — Primeira publicação

Além do fluxo de atualização (passos 3 a 6), orientar:

1. **O que já existe no servidor:** se o tema filho já existir lá (alguém criou antes), o plano mostra o que seria substituído. Isso precisa de autorização explícita, como qualquer substituição.
2. **Banco de dados (só se o conteúdo foi montado no MAMP):** migração única, feita pelo usuário com orientação. Nunca por script automático.
   - Caminho recomendado: plugin de migração (All-in-One WP Migration ou Duplicator). Exportar do local, importar na Hostinger e trocar as URLs (`http://localhost:8888/<pasta>` → `https://<dominio>`). Esses plugins fazem a troca sozinhos.
   - Avisar: a importação **substitui o banco de produção inteiro**. Só fazer em site novo/vazio ou com backup do hPanel feito antes. Usuários e senhas do painel passam a ser os do local.
   - Se o site de produção já tiver conteúdo real, **não migrar banco**: publicar só o tema e recriar ou importar as páginas (templates do Elementor em `elementor/`, páginas por código criadas no painel com o modelo certo).
3. **Depois do envio:** ativar o tema filho em Aparência → Temas (o usuário faz; não ativar por WP-CLI sem pedir). Conferir Configurações → Links permanentes ("Nome do post"), páginas com o modelo certo e o rodapé com o crédito Kapila.
4. **Checar URLs:** `siteurl` e `home` com `https://<dominio>`, sem `localhost` nas páginas: `curl -s https://<dominio>/ | grep -c localhost` deve dar 0.

## Passo 3 — Comparar (só leitura)

```bash
scripts/publicar-wp.sh comparar "clientes/<Nome>/wordpress"
```

Baixa uma cópia do tema do servidor e compara arquivo por arquivo (conteúdo, não data). Gera o plano em `.backups/plano-para-aprovar.txt` com:
- **Novos**: serão enviados
- **Alterados**: serão substituídos
- **Só no servidor**: ficam lá, a não ser que o usuário autorize excluir

Nunca sobem: `.md`, `.DS_Store`, `.git*`, `.gitkeep`, `node_modules`.

Se aparecer algo em "Alterados" que o usuário não mudou aqui, alguém editou direto no servidor. Mostrar a diferença (`diff` entre `tema/<arquivo>` e `.backups/comparacao/<slug>/<arquivo>`) e perguntar antes de seguir.

## Passo 4 — Confirmação obrigatória

Mostrar o plano completo (listas acima) e o destino (`<ssh_host>:<wp_raiz>/wp-content/themes/<slug>`). Perguntar com `AskUserQuestion`:

- "Publicar" (envia novos e alterados, não exclui nada)
- "Publicar e excluir os arquivos só do servidor" (só oferecer se houver itens nessa lista)
- "Cancelar"

Sem resposta afirmativa, parar.

## Passo 5 — Publicar

```bash
scripts/publicar-wp.sh publicar "clientes/<Nome>/wordpress" --confirmado            # sem exclusões
scripts/publicar-wp.sh publicar "clientes/<Nome>/wordpress" --confirmado --excluir  # só se autorizado
```

O script, nesta ordem:
1. Valida o tema local e a sintaxe do PHP.
2. Confere se WordPress e Hello Elementor existem no servidor.
3. Baixa o backup do tema atual em `.backups/<data>/`.
4. Refaz a comparação e **aborta** se ela não bater com o plano aprovado.
5. Envia.
6. Testa o site (HTTP 200, sem erro de PHP, `style.css` do tema acessível).
7. Registra no histórico do `deploy.md`.

## Passo 6 — Resultado

```
✓ Publicado: <n> novos, <n> alterados, <n> excluídos
Backup: clientes/<Nome>/wordpress/.backups/<data>/
Site: <site_url> → OK
Histórico: deploy.md
```

Se a verificação falhar, mostrar o erro e oferecer a restauração (com nova confirmação):

```bash
scripts/publicar-wp.sh restaurar "clientes/<Nome>/wordpress" <AAAAMMDD-HHMMSS> --confirmado
```

Na primeira publicação não há backup. Se quebrar, a saída é reativar o Hello Elementor em Aparência → Temas.

## O que este fluxo NÃO publica

Páginas, textos dos campos editáveis, menus, configurações e templates do Elementor moram no **banco**. Mudança nesse conteúdo se faz no painel do site no ar (ou por exportação e importação de template do Elementor), não aqui.
