# WordPress — {{CLIENTE}}

> Criado em {{DATA}} pelo `/novo-wp`. Publicação: `/publicar-wp` (detalhes em `deploy.md`).

## Resumo

| | |
|---|---|
| Tema filho | `{{TEMA_SLUG}}` (pai: Hello Elementor, nunca editado) |
| Local (MAMP) | `/Applications/MAMP/htdocs/{{MAMP_PASTA}}/` → http://localhost:8888/{{MAMP_PASTA}}/ |
| Produção | {{SITE_URL}} |
| Elementor Pro | instalado e licenciado manualmente em cada WordPress |

## Pastas

```
wordpress/
  tema/        código do tema filho (é a única coisa que sobe por SFTP/rsync)
  elementor/   templates exportados do Elementor Pro (.json), pra versionar
  deploy.md    dados não sensíveis da publicação + histórico
  .backups/    cópias do servidor antes de cada publicação (fora do Git)
```

No MAMP, `wp-content/themes/{{TEMA_SLUG}}` é um link simbólico para `tema/`: editou aqui, recarregou o navegador, viu.

## Páginas

| Página | Tipo | Template / origem | Observações |
|---|---|---|---|
| | código / Elementor | `page-templates/<nome>.php` / editor | |

- **Por código:** `tema/page-templates/<nome>.php` + `tema/assets/css/<nome>.css` (+ `js/<nome>.js`). No painel: Páginas → Adicionar → Modelo "Kapila · …". Textos editáveis em `tema/inc/campos.php`.
- **Elementor:** criada no painel. Exportar o template pra `elementor/` quando quiser versionar.

## O que mora onde

- **Arquivos (tema/):** sobem com `/publicar-wp`.
- **Banco de dados (páginas do Elementor, menus, configurações, campos editáveis):** não sobem por SFTP. Primeira publicação = migração única (ver `/publicar-wp`). Depois disso, conteúdo se edita direto no site no ar.

## Regras

- Nunca editar o tema pai `hello-elementor`.
- Nunca editar arquivos do tema direto na Hostinger: o próximo `/publicar-wp` mostra a diferença, mas o certo é tudo passar por aqui.
- Plugin novo só com motivo claro e anotado aqui.
- Rodapé: crédito "Desenvolvido por Kapila" (canvas: já no template; Elementor: widget Shortcode `[kapila_credito]` no rodapé do Theme Builder).
