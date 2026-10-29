<?php
/**
 * Template Name: Kapila · Página por código (com cabeçalho do site)
 * Kapila Layout: site
 *
 * Conteúdo por código entre o cabeçalho e o rodapé do site (Theme Builder do
 * Elementor Pro ou, sem ele, os do Hello). Bom para páginas que precisam do
 * menu do site. O crédito da Kapila vem do rodapé do site ([kapila_credito]).
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

get_header();
?>

<main class="kapila-pagina">
	<section class="hero">
		<h1><?php echo esc_html( kapila_campo( 'titulo', get_the_title() ) ); ?></h1>
		<p class="hero__texto"><?php echo esc_html( kapila_campo( 'subtitulo', 'Texto de apoio da página.' ) ); ?></p>
	</section>
</main>

<?php
get_footer();
