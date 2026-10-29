<?php
/**
 * Carregamento de CSS e JS, sempre via wp_enqueue_*.
 *
 * Convenção (sem configuração): a página que usa page-templates/<nome>.php carrega
 * automaticamente, se existirem:
 *   assets/css/base.css     → tokens e base compartilhados das páginas por código
 *   assets/css/<nome>.css   → estilo da página
 *   assets/js/<nome>.js     → script da página (rodapé, defer)
 * Páginas do Elementor não recebem nada disso, só o style.css do tema filho.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Google Fonts das páginas por código. Deixe '' se usar fontes locais (assets/fonts/).
 * Ex.: 'https://fonts.googleapis.com/css2?family=Inter:wght@400;600;800&display=swap'
 */
define( 'KAPILA_FONTES_URL', '' );

function kapila_asset_url( $caminho ) {
	return KAPILA_TEMA_URI . '/assets/' . ltrim( $caminho, '/' );
}

function kapila_asset_existe( $caminho ) {
	return file_exists( KAPILA_TEMA_DIR . '/assets/' . ltrim( $caminho, '/' ) );
}

// Versão = data de modificação do arquivo: o navegador nunca fica com cache velho após publicar.
function kapila_asset_versao( $caminho ) {
	$arquivo = KAPILA_TEMA_DIR . '/assets/' . ltrim( $caminho, '/' );
	return file_exists( $arquivo ) ? (string) filemtime( $arquivo ) : wp_get_theme()->get( 'Version' );
}

// Páginas canvas não usam o reset/tema do Hello: o HTML é 100% nosso.
add_filter(
	'hello_elementor_enqueue_style',
	function ( $carregar ) {
		return kapila_e_canvas() ? false : $carregar;
	}
);
add_filter(
	'hello_elementor_enqueue_theme_style',
	function ( $carregar ) {
		return kapila_e_canvas() ? false : $carregar;
	}
);

add_action(
	'wp_enqueue_scripts',
	function () {
		$versao_tema = wp_get_theme()->get( 'Version' );

		// style.css do tema filho: em todas as páginas.
		wp_enqueue_style( 'kapila-child', get_stylesheet_uri(), array(), $versao_tema );

		$template = kapila_template_atual();
		if ( ! $template ) {
			return; // página do Elementor ou padrão: nada além do style.css
		}

		if ( kapila_e_canvas() ) {
			wp_dequeue_style( 'hello-elementor-header-footer' );
		}

		$dependencias = array();

		if ( KAPILA_FONTES_URL ) {
			wp_enqueue_style( 'kapila-fontes', KAPILA_FONTES_URL, array(), null );
			$dependencias[] = 'kapila-fontes';
		}

		if ( kapila_asset_existe( 'css/base.css' ) ) {
			wp_enqueue_style( 'kapila-base', kapila_asset_url( 'css/base.css' ), $dependencias, kapila_asset_versao( 'css/base.css' ) );
			$dependencias = array( 'kapila-base' );
		}

		$css = 'css/' . $template . '.css';
		if ( kapila_asset_existe( $css ) ) {
			wp_enqueue_style( 'kapila-' . $template, kapila_asset_url( $css ), $dependencias, kapila_asset_versao( $css ) );
		}

		$js = 'js/' . $template . '.js';
		if ( kapila_asset_existe( $js ) ) {
			wp_enqueue_script(
				'kapila-' . $template,
				kapila_asset_url( $js ),
				array(),
				kapila_asset_versao( $js ),
				array(
					'in_footer' => true,
					'strategy'  => 'defer',
				)
			);
		}
	},
	20 // depois do Hello (prioridade 10)
);

// Painel: seletor de imagem da biblioteca de mídia para os campos editáveis.
add_action(
	'admin_enqueue_scripts',
	function ( $tela ) {
		$screen = get_current_screen();
		if ( ! in_array( $tela, array( 'post.php', 'post-new.php' ), true ) || ! $screen || 'page' !== $screen->post_type ) {
			return;
		}
		wp_enqueue_media();
		wp_enqueue_script(
			'kapila-admin-campos',
			kapila_asset_url( 'js/admin-campos.js' ),
			array( 'jquery' ),
			kapila_asset_versao( 'js/admin-campos.js' ),
			true
		);
	}
);
