<?php
/**
 * Setup do tema e helpers para as páginas por código.
 *
 * Páginas por código = arquivos em page-templates/. Cada um declara no cabeçalho:
 *   Template Name: <nome que aparece no painel>
 *   Kapila Layout: canvas | site
 *     canvas → HTML completo próprio, sem cabeçalho/rodapé do Hello/Elementor
 *     site   → usa get_header()/get_footer(), ou seja, o cabeçalho e rodapé do
 *              Theme Builder do Elementor Pro (ou os do Hello, se não houver)
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

add_action(
	'after_setup_theme',
	function () {
		// O Hello já declara title-tag, thumbnails, custom-logo etc. Aqui só o que é nosso.
		register_nav_menus(
			array(
				'kapila-principal' => __( 'Menu das páginas por código', 'kapila-child' ),
			)
		);
	}
);

/**
 * Nome do template por código da página atual (ex.: "pagina-codigo"), ou '' se
 * a página não usa um template de page-templates/ (ex.: páginas do Elementor).
 */
function kapila_template_atual() {
	if ( ! is_singular() ) {
		return '';
	}
	$template = get_page_template_slug( get_queried_object_id() );
	if ( ! $template || 0 !== strpos( $template, 'page-templates/' ) ) {
		return '';
	}
	return basename( $template, '.php' );
}

/**
 * Layout declarado no cabeçalho do template ("canvas" por padrão).
 */
function kapila_template_layout( $template ) {
	$arquivo = KAPILA_TEMA_DIR . '/page-templates/' . $template . '.php';
	if ( ! $template || ! file_exists( $arquivo ) ) {
		return '';
	}
	$dados = get_file_data( $arquivo, array( 'layout' => 'Kapila Layout' ) );
	return 'site' === trim( $dados['layout'] ) ? 'site' : 'canvas';
}

function kapila_e_canvas() {
	return 'canvas' === kapila_template_layout( kapila_template_atual() );
}
