# Publicação — {{CLIENTE}}

> Só informações NÃO sensíveis. Senha, token ou chave privada nunca entram aqui
> (nem em nenhum arquivo do projeto). A autenticação fica no `~/.ssh/config` e na chave SSH do Mac.

## Configuração

O `scripts/publicar-wp.sh` lê este bloco. Enquanto tiver `{{...}}`, a publicação fica bloqueada.

```config
metodo: rsync
ssh_host: {{SSH_HOST}}
ssh_porta:
wp_raiz: {{WP_RAIZ}}
tema_slug: {{TEMA_SLUG}}
site_url: {{SITE_URL}}
```

- `metodo`: `rsync` (SSH + rsync, preferido) ou `sftp` (alternativa, mesma chave SSH).
- `ssh_host`: apelido do servidor no `~/.ssh/config` (ex.: `hostinger-cliente`). Com apelido, deixe `ssh_porta` vazio.
- `wp_raiz`: pasta do WordPress no servidor, relativa à home do usuário SSH (ex.: `domains/dominio.com.br/public_html`). Sem `~`, sem espaços.
- `tema_slug`: nome da pasta do tema filho em `wp-content/themes/`.
- `site_url`: endereço público, com `https://`, sem barra no final.

Exemplo de `~/.ssh/config` (dados do hPanel → Avançado → Acesso SSH):

```
Host hostinger-cliente
  HostName <ip do hPanel>
  Port 65002
  User <usuário u123456789>
  IdentityFile ~/.ssh/id_ed25519
  IdentitiesOnly yes
```

## Checklist da primeira publicação

- [ ] SSH ativado no hPanel e chave pública (`id_ed25519.pub`) cadastrada
- [ ] `ssh <apelido>` conecta sem pedir senha
- [ ] WordPress instalado na Hostinger, Hello Elementor e Elementor Pro (com licença) instalados
- [ ] `/publicar-wp` → verificação ok
- [ ] Banco migrado (se o conteúdo foi montado no local) e URLs trocadas
- [ ] Tema filho enviado e ativado em Aparência → Temas
- [ ] Rodapé com "Desenvolvido por Kapila"

## Histórico

| Data | Método | Tipo | Arquivos | Backup | Resultado |
|---|---|---|---|---|---|
