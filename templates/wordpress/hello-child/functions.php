<?php
/**
 * Tema filho do Hello Elementor — Kapila.
 *
 * O tema pai (hello-elementor) nunca é editado: toda personalização vive aqui.
 * Cada responsabilidade fica num arquivo em inc/.
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

define( 'KAPILA_TEMA_DIR', get_stylesheet_directory() );
define( 'KAPILA_TEMA_URI', get_stylesheet_directory_uri() );

require_once KAPILA_TEMA_DIR . '/inc/setup.php';   // menus e helpers de template
require_once KAPILA_TEMA_DIR . '/inc/assets.php';  // CSS/JS via wp_enqueue_*
require_once KAPILA_TEMA_DIR . '/inc/campos.php';  // textos/imagens/links editáveis no painel
require_once KAPILA_TEMA_DIR . '/inc/credito.php'; // "Desenvolvido por Kapila"
