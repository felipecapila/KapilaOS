<?php
/**
 * Crédito obrigatório em todo site de cliente: "Desenvolvido por Kapila".
 *
 * - Páginas canvas: o template chama kapila_credito_html() no próprio rodapé.
 * - Páginas do Elementor: no rodapé do Theme Builder (Elementor Pro), adicionar um
 *   widget "Shortcode" com [kapila_credito].
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

function kapila_credito_html() {
	return '<p class="kapila-credito">Desenvolvido por <a href="https://felipecapila.com.br" target="_blank" rel="noopener">Kapila</a></p>';
}

add_shortcode( 'kapila_credito', 'kapila_credito_html' );
