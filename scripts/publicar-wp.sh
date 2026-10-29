#!/bin/bash
# publicar-wp.sh — publica o tema filho de um projeto WordPress na Hostinger.
# Usado pela skill /publicar-wp. Lê a configuração do bloco ```config de <pasta>/deploy.md.
#
#   scripts/publicar-wp.sh verificar   <clientes/X/wordpress>   # só leitura: local, conexão, servidor, site
#   scripts/publicar-wp.sh comparar    <clientes/X/wordpress>   # só leitura: gera o plano (novos/alterados/só no servidor)
#   scripts/publicar-wp.sh publicar    <clientes/X/wordpress> --confirmado [--excluir]
#   scripts/publicar-wp.sh restaurar   <clientes/X/wordpress> <AAAAMMDD-HHMMSS> --confirmado
#   scripts/publicar-wp.sh testar-site <clientes/X/wordpress>
#
# Garantias:
#   - Só mexe em wp-content/themes/<tema_slug>. Nunca no core, plugins, uploads, banco ou tema pai.
#   - "publicar" exige --confirmado e um plano gerado por "comparar". Se o servidor ou os arquivos
#     locais mudarem entre os dois, aborta.
#   - Antes de enviar, baixa uma cópia completa do tema do servidor em <pasta>/.backups/<data>/.
#   - Nada é excluído no servidor sem --excluir.
#
# KAPILA_WP_TESTE=1 trata wp_raiz como pasta local (sem SSH). Só para testar o script.

PASTA="${2:-}"
ACAO="${1:-}"

erro() { echo "ERRO: $*" >&2; exit 1; }
info() { echo "→ $*"; }

uso() { sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 1; }
[ -n "$ACAO" ] && [ -n "$PASTA" ] || uso

CONFIRMADO=0; EXCLUIR=0; BACKUP_TS=""
shift 2
for arg in "$@"; do
	case "$arg" in
		--confirmado) CONFIRMADO=1 ;;
		--excluir) EXCLUIR=1 ;;
		[0-9]*-[0-9]*) BACKUP_TS="$arg" ;;
		*) erro "opção desconhecida: $arg" ;;
	esac
done

PASTA="$(cd "$PASTA" 2>/dev/null && pwd)" || erro "pasta não encontrada"
DEPLOY_MD="$PASTA/deploy.md"
TEMA_LOCAL="$PASTA/tema"
BACKUPS="$PASTA/.backups"
PLANO_APROVADO="$BACKUPS/plano-para-aprovar.txt"
TESTE="${KAPILA_WP_TESTE:-0}"

[ -f "$DEPLOY_MD" ] || erro "não achei $DEPLOY_MD"
[ -d "$TEMA_LOCAL" ] || erro "não achei a pasta do tema: $TEMA_LOCAL"

# ---------------------------------------------------------------- configuração

cfg() {
	awk -v k="$1" '
		/^```config/ { dentro = 1; next }
		/^```/       { dentro = 0 }
		dentro && index($0, k ":") == 1 { sub("^" k ":[ \t]*", ""); sub(/[ \t\r]+$/, ""); print; exit }
	' "$DEPLOY_MD"
}

METODO="$(cfg metodo)"; HOST="$(cfg ssh_host)"; PORTA="$(cfg ssh_porta)"
WP_RAIZ="$(cfg wp_raiz)"; SLUG="$(cfg tema_slug)"; SITE_URL="$(cfg site_url)"; SITE_URL="${SITE_URL%/}"

grep -A8 '^```config' "$DEPLOY_MD" | grep -q '{{' && erro "deploy.md ainda tem {{...}} no bloco config. Preencha antes."
case "$METODO" in rsync|sftp) ;; *) erro "metodo deve ser rsync ou sftp (está: '$METODO')" ;; esac
[ -n "$HOST" ] || [ "$TESTE" = 1 ] || erro "ssh_host vazio"
echo "$SLUG" | grep -Eq '^[a-z0-9][a-z0-9-]*$' || erro "tema_slug inválido: '$SLUG'"
[ "$SLUG" = "hello-elementor" ] && erro "tema_slug não pode ser o tema pai"
echo "$WP_RAIZ" | grep -Eq '^[A-Za-z0-9._/-]+$' || erro "wp_raiz vazio ou com caracteres não permitidos: '$WP_RAIZ'"
case "/$WP_RAIZ/" in */../*|//) erro "wp_raiz inválido: '$WP_RAIZ'" ;; esac
[ -z "$PORTA" ] || echo "$PORTA" | grep -Eq '^[0-9]+$' || erro "ssh_porta inválida"

REMOTO_TEMA="$WP_RAIZ/wp-content/themes/$SLUG"
SSH_OPTS="-o BatchMode=yes -o ConnectTimeout=15"
[ -n "$PORTA" ] && SSH_OPTS="$SSH_OPTS -p $PORTA"
SFTP_OPTS="-o BatchMode=yes -o ConnectTimeout=15"
[ -n "$PORTA" ] && SFTP_OPTS="$SFTP_OPTS -P $PORTA"

# ---------------------------------------------------------------- servidor

# Executa um script bash no servidor (ou localmente em modo teste), com argumentos já validados.
remoto_script() {
	if [ "$TESTE" = 1 ]; then bash -s -- "$@"; else ssh $SSH_OPTS "$HOST" bash -s -- "$@"; fi
}

sftp_lote() { # lê comandos sftp do stdin
	sftp $SFTP_OPTS -b - "$HOST"
}

remoto_existe() { # $1 = caminho no servidor
	if [ "$TESTE" = 1 ]; then [ -e "$1" ]; return; fi
	if [ "$METODO" = rsync ]; then
		ssh $SSH_OPTS "$HOST" test -e "$1"
	else
		printf 'ls "%s"\n' "$1" | sftp_lote >/dev/null 2>&1
	fi
}

# Baixa o tema do servidor para $1/<slug>. Retorno: 0 ok, 2 tema não existe no servidor, 1 erro.
baixar_tema() {
	local destino="$1"
	mkdir -p "$destino" || return 1
	remoto_existe "$REMOTO_TEMA" || return 2
	if [ "$TESTE" = 1 ]; then
		if [ "$METODO" = rsync ]; then rsync -rl "$REMOTO_TEMA/" "$destino/$SLUG/"; else cp -R "$REMOTO_TEMA" "$destino/"; fi
	elif [ "$METODO" = rsync ]; then
		rsync -rl -e "ssh $SSH_OPTS" "$HOST:$REMOTO_TEMA/" "$destino/$SLUG/"
	else
		printf 'lcd "%s"\nget -r %s\n' "$destino" "$REMOTO_TEMA" | sftp_lote >/dev/null
	fi
}

# ---------------------------------------------------------------- comparação

# Arquivos que nunca sobem nem são excluídos no servidor.
excluido() {
	case "/$1/" in
		*/.DS_Store/*|*/.git*|*/node_modules/*|*.md/|*/.gitkeep/*) return 0 ;;
	esac
	return 1
}

listar() { # arquivos relativos de $1, sem os excluídos
	[ -d "$1" ] || return 0
	(cd "$1" && find . \( -type f -o -type l \) | sed 's|^\./||' | LC_ALL=C sort) | while IFS= read -r rel; do
		excluido "$rel" || echo "$rel"
	done
}

# Plano: linhas "NOVO<TAB>arquivo", "ALTERADO<TAB>arquivo", "SO_SERVIDOR<TAB>arquivo"
gerar_plano() { # $1 = cópia do servidor (pode não existir)
	local servidor="$1"
	listar "$TEMA_LOCAL" | while IFS= read -r rel; do
		if [ ! -e "$servidor/$rel" ]; then printf 'NOVO\t%s\n' "$rel"
		elif ! cmp -s "$TEMA_LOCAL/$rel" "$servidor/$rel"; then printf 'ALTERADO\t%s\n' "$rel"
		fi
	done
	listar "$servidor" | while IFS= read -r rel; do
		[ -e "$TEMA_LOCAL/$rel" ] || printf 'SO_SERVIDOR\t%s\n' "$rel"
	done
}

mostrar_plano() {
	local plano="$1" n
	for tipo in NOVO ALTERADO SO_SERVIDOR; do
		n=$(grep -c "^$tipo	" "$plano")
		case "$tipo" in
			NOVO) titulo="Novos (serão enviados)" ;;
			ALTERADO) titulo="Alterados (serão substituídos)" ;;
			SO_SERVIDOR) titulo="Só no servidor (só serão EXCLUÍDOS com --excluir)" ;;
		esac
		echo; echo "$titulo: $n"
		grep "^$tipo	" "$plano" | cut -f2 | sed 's/^/   /'
	done
}

# ---------------------------------------------------------------- verificações

php_bin() {
	command -v php 2>/dev/null && return
	ls -d /Applications/MAMP/bin/php/php8*/bin/php 2>/dev/null | sort -V | tail -1
}

checar_local() {
	grep -Eq '^[[:space:]]*Template:[[:space:]]*hello-elementor[[:space:]]*$' "$TEMA_LOCAL/style.css" 2>/dev/null \
		|| erro "tema/style.css sem 'Template: hello-elementor'"
	grep -q '{{' "$TEMA_LOCAL/style.css" && erro "tema/style.css ainda tem {{...}}"
	local php; php="$(php_bin)"
	if [ -z "$php" ]; then info "PHP não encontrado: sintaxe não validada"; return; fi
	local falhas=0
	while IFS= read -r f; do
		"$php" -l "$f" >/dev/null 2>&1 || { "$php" -l "$f" 2>&1 | head -3; falhas=1; }
	done < <(find "$TEMA_LOCAL" -name '*.php')
	[ "$falhas" = 0 ] || erro "erro de sintaxe PHP no tema (acima). Nada foi publicado."
	info "local ok: tema filho do hello-elementor, PHP sem erro de sintaxe"
}

testar_site() {
	if [ "$TESTE" = 1 ]; then info "site: teste HTTP pulado (modo teste)"; return 0; fi
	[ -n "$SITE_URL" ] || { info "site_url vazio: teste HTTP pulado"; return 0; }
	local tmp codigo codigo_css ok=0
	tmp="$(mktemp)"
	codigo=$(curl -sL -o "$tmp" -w '%{http_code}' --max-time 30 "$SITE_URL/")
	codigo_css=$(curl -sL -o /dev/null -w '%{http_code}' --max-time 30 "$SITE_URL/wp-content/themes/$SLUG/style.css")
	echo "   $SITE_URL/ → HTTP $codigo"
	echo "   style.css do tema filho → HTTP $codigo_css"
	if grep -qiE 'critical error|erro crítico|Fatal error|Parse error' "$tmp"; then
		echo "   A página mostra erro de PHP."; ok=1
	fi
	rm -f "$tmp"
	[ "$codigo" = 200 ] && [ "$codigo_css" = 200 ] && [ "$ok" = 0 ]
}

historico() { # $1 tipo, $2 arquivos, $3 backup, $4 resultado
	printf '| %s | %s | %s | %s | %s | %s |\n' "$(date '+%Y-%m-%d %H:%M')" "$METODO" "$1" "$2" "$3" "$4" >> "$DEPLOY_MD"
}

# ---------------------------------------------------------------- ações

verificar() {
	checar_local
	if [ "$TESTE" != 1 ]; then
		info "conectando em $HOST ($METODO)…"
		if [ "$METODO" = rsync ]; then
			ssh $SSH_OPTS "$HOST" true 2>/dev/null || erro "SSH sem acesso por chave. Veja o ~/.ssh/config e a chave cadastrada no hPanel."
		else
			echo "pwd" | sftp_lote >/dev/null 2>&1 || erro "SFTP sem acesso por chave. Veja o ~/.ssh/config e a chave cadastrada no hPanel."
		fi
	fi
	echo
	if [ "$METODO" = rsync ]; then
		remoto_script "$WP_RAIZ" "$SLUG" <<'SCRIPT'
R="$1"; S="$2"
if ! cd "$R" 2>/dev/null; then echo "wp_raiz: NÃO EXISTE ($R)"; exit 0; fi
echo "wp_raiz: ok ($(pwd))"
[ -f wp-config.php ] && echo "WordPress: instalado" || echo "WordPress: NÃO encontrado (sem wp-config.php)"
v=$(sed -n "s/^\$wp_version = '\(.*\)';/\1/p" wp-includes/version.php 2>/dev/null); echo "versão WP: ${v:-?}"
hv=$(sed -n 's/^Version:[[:space:]]*//p' wp-content/themes/hello-elementor/style.css 2>/dev/null | head -1)
[ -d wp-content/themes/hello-elementor ] && echo "Hello Elementor: instalado ($hv)" || echo "Hello Elementor: NÃO instalado"
[ -d wp-content/plugins/elementor ] && echo "Elementor: instalado" || echo "Elementor: NÃO instalado"
[ -d wp-content/plugins/elementor-pro ] && echo "Elementor Pro: instalado" || echo "Elementor Pro: NÃO instalado"
[ -d "wp-content/themes/$S" ] && echo "tema filho ($S): JÁ EXISTE no servidor → modo atualização" || echo "tema filho ($S): não existe → primeira publicação"
echo "PHP: $(php -r 'echo PHP_VERSION;' 2>/dev/null || echo '?')"
command -v rsync >/dev/null 2>&1 && echo "rsync no servidor: ok" || echo "rsync no servidor: NÃO (use metodo: sftp)"
if command -v wp >/dev/null 2>&1 && [ -f wp-config.php ]; then
	echo "WP-CLI: ok"
	echo "siteurl (banco): $(wp option get siteurl 2>/dev/null)"
	echo "tema ativo: $(wp option get stylesheet 2>/dev/null)"
fi
SCRIPT
	else
		for item in "wp-config.php:WordPress" "wp-content/themes/hello-elementor:Hello Elementor" \
			"wp-content/plugins/elementor:Elementor" "wp-content/plugins/elementor-pro:Elementor Pro"; do
			remoto_existe "$WP_RAIZ/${item%%:*}" && echo "${item#*:}: encontrado" || echo "${item#*:}: NÃO encontrado"
		done
		remoto_existe "$REMOTO_TEMA" && echo "tema filho ($SLUG): JÁ EXISTE → modo atualização" || echo "tema filho ($SLUG): não existe → primeira publicação"
	fi
	echo
	testar_site && info "site respondendo" || info "site não respondeu como esperado (normal se o domínio ainda não aponta pra Hostinger)"
}

comparar() {
	checar_local
	mkdir -p "$BACKUPS"
	local espelho="$BACKUPS/comparacao"
	rm -rf "$espelho"
	baixar_tema "$espelho"; local r=$?
	[ "$r" = 1 ] && erro "falha ao baixar o tema do servidor"
	[ "$r" = 2 ] && info "tema filho ainda não existe no servidor: tudo será novo"
	gerar_plano "$espelho/$SLUG" > "$PLANO_APROVADO"
	echo "Plano: $METODO → $HOST:$REMOTO_TEMA"
	mostrar_plano "$PLANO_APROVADO"
	echo
	if [ ! -s "$PLANO_APROVADO" ]; then
		info "nada a publicar: servidor igual ao local"
		rm -f "$PLANO_APROVADO"
	else
		info "plano salvo. Para publicar (após aprovação): publicar --confirmado [--excluir]"
	fi
}

enviar_rsync() { # $1 = 1 para excluir
	local args="-rlc --exclude=.DS_Store --exclude=.git* --exclude=node_modules --exclude=*.md --exclude=.gitkeep"
	[ "$1" = 1 ] && args="$args --delete"
	set -f # os padrões de --exclude não podem virar nomes de arquivo
	if [ "$TESTE" = 1 ]; then
		rsync $args "$TEMA_LOCAL/" "$REMOTO_TEMA/"
	else
		rsync $args -e "ssh $SSH_OPTS" "$TEMA_LOCAL/" "$HOST:$REMOTO_TEMA/"
	fi
	local r=$?; set +f; return $r
}

enviar_sftp() { # $1 = 1 para excluir, $2 = plano, $3 = arquivo de lote
	local excluir="$1" plano="$2" lote="$3"
	{
		echo "-mkdir $REMOTO_TEMA"
		grep -E '^(NOVO|ALTERADO)	' "$plano" | cut -f2 | while IFS= read -r rel; do
			d="$(dirname "$rel")"
			while [ "$d" != "." ]; do echo "$d"; d="$(dirname "$d")"; done
		done | LC_ALL=C sort -u | awk '{ print length, $0 }' | sort -n | cut -d' ' -f2- | sed "s|^|-mkdir $REMOTO_TEMA/|"
		grep -E '^(NOVO|ALTERADO)	' "$plano" | cut -f2 | while IFS= read -r rel; do
			printf 'put "%s" "%s"\n' "$TEMA_LOCAL/$rel" "$REMOTO_TEMA/$rel"
		done
		if [ "$excluir" = 1 ]; then
			grep '^SO_SERVIDOR	' "$plano" | cut -f2 | while IFS= read -r rel; do
				printf 'rm "%s"\n' "$REMOTO_TEMA/$rel"
			done
		fi
	} > "$lote"
	if [ "$TESTE" = 1 ]; then info "modo teste: lote SFTP gerado e não executado ($lote)"; return 0; fi
	sftp_lote < "$lote"
}

publicar() {
	[ "$CONFIRMADO" = 1 ] || erro "publicar exige --confirmado (autorização explícita depois de ver o plano)"
	[ -f "$PLANO_APROVADO" ] || erro "não há plano aprovado. Rode 'comparar' antes."
	checar_local

	remoto_existe "$WP_RAIZ/wp-config.php" || erro "WordPress não encontrado em $WP_RAIZ no servidor. Nada foi enviado."
	remoto_existe "$WP_RAIZ/wp-content/themes/hello-elementor" || erro "Hello Elementor não está instalado no servidor. Instale pelo painel antes."

	local ts backup tipo r
	ts="$(date '+%Y%m%d-%H%M%S')"
	backup="$BACKUPS/$ts"
	baixar_tema "$backup"; r=$?
	[ "$r" = 1 ] && erro "falha no backup do servidor. Nada foi enviado."
	if [ "$r" = 2 ]; then tipo="primeira publicação"; rmdir "$backup" 2>/dev/null; backup="—"
	else tipo="atualização"; info "backup do servidor: .backups/$ts/$SLUG"; fi

	local plano_atual="$BACKUPS/plano-$ts.txt"
	gerar_plano "$backup/$SLUG" > "$plano_atual"
	if ! cmp -s "$plano_atual" "$PLANO_APROVADO"; then
		rm -f "$PLANO_APROVADO"
		erro "o servidor ou os arquivos locais mudaram desde a comparação. Rode 'comparar' de novo. Nada foi enviado."
	fi

	local n_novo n_alt n_exc resumo
	n_novo=$(grep -c '^NOVO	' "$plano_atual"); n_alt=$(grep -c '^ALTERADO	' "$plano_atual")
	n_exc=0; [ "$EXCLUIR" = 1 ] && n_exc=$(grep -c '^SO_SERVIDOR	' "$plano_atual")
	resumo="$n_novo novos, $n_alt alterados, $n_exc excluídos"
	[ "$backup" = "—" ] || backup=".backups/$ts"

	info "enviando ($tipo): $resumo"
	if [ "$METODO" = rsync ]; then enviar_rsync "$EXCLUIR"; else enviar_sftp "$EXCLUIR" "$plano_atual" "$BACKUPS/lote-$ts.sftp"; fi
	if [ $? != 0 ]; then
		historico "$tipo" "$resumo" "$backup" "FALHOU no envio"
		erro "o envio falhou. Backup em $backup. Para voltar: restaurar $ts --confirmado"
	fi
	rm -f "$PLANO_APROVADO"

	info "verificando o site…"
	if testar_site; then
		historico "$tipo" "$resumo" "$backup" "OK"
		info "publicado e verificado"
	else
		historico "$tipo" "$resumo" "$backup" "publicado, verificação FALHOU"
		echo "ATENÇÃO: o site não passou na verificação."
		[ "$backup" != "—" ] && echo "Para voltar: scripts/publicar-wp.sh restaurar \"$PASTA\" $ts --confirmado"
		exit 2
	fi
}

restaurar() {
	[ "$CONFIRMADO" = 1 ] || erro "restaurar exige --confirmado"
	[ -n "$BACKUP_TS" ] && [ -d "$BACKUPS/$BACKUP_TS/$SLUG" ] || erro "backup não encontrado: .backups/$BACKUP_TS/$SLUG"
	local origem="$BACKUPS/$BACKUP_TS/$SLUG"
	info "restaurando o tema no servidor a partir de .backups/$BACKUP_TS"
	if [ "$METODO" = rsync ]; then
		# --delete aqui só deixa wp-content/themes/<slug> idêntico ao backup.
		if [ "$TESTE" = 1 ]; then rsync -rlc --delete "$origem/" "$REMOTO_TEMA/"
		else rsync -rlc --delete -e "ssh $SSH_OPTS" "$origem/" "$HOST:$REMOTO_TEMA/"; fi
	else
		local lote="$BACKUPS/restaurar-$BACKUP_TS.sftp"
		(cd "$origem" && find . -type d | sed 's|^\./||' | grep -v '^\.$' | LC_ALL=C sort | sed "s|^|-mkdir $REMOTO_TEMA/|") > "$lote"
		(cd "$origem" && find . -type f | sed 's|^\./||') | while IFS= read -r rel; do
			printf 'put "%s" "%s"\n' "$origem/$rel" "$REMOTO_TEMA/$rel"
		done >> "$lote"
		echo "(SFTP: arquivos criados depois do backup não são removidos)"
		[ "$TESTE" = 1 ] || sftp_lote < "$lote" || erro "falha ao restaurar"
	fi
	historico "restauração" "backup $BACKUP_TS" ".backups/$BACKUP_TS" "OK"
	testar_site && info "restaurado e verificado" || echo "ATENÇÃO: restaurado, mas o site não passou na verificação."
}

case "$ACAO" in
	verificar) verificar ;;
	comparar) comparar ;;
	publicar) publicar ;;
	restaurar) restaurar ;;
	testar-site) testar_site && info "site ok" || { echo "site com problema"; exit 2; } ;;
	*) uso ;;
esac
