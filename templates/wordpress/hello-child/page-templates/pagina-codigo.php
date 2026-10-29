<?php
/**
 * Template Name: Kapila · Página por código
 * Kapila Layout: canvas
 *
 * Modelo de página completa por código: HTML, CSS e JS próprios, no mesmo padrão
 * dos sites estáticos da Kapila, sem cabeçalho/rodapé do Hello ou do Elementor.
 * Para criar uma página nova: copie este arquivo com outro nome (ex.: links.php),
 * troque o "Template Name" e crie assets/css/links.css (e assets/js/links.js se precisar).
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

$imagem = kapila_imagem_url( 'imagem' );
?><!doctype html>
<html <?php language_attributes(); ?>>
<head>
	<meta charset="<?php bloginfo( 'charset' ); ?>">
	<meta name="viewport" content="width=device-width, initial-scale=1">
	<?php wp_head(); ?>
</head>
<body <?php body_class( 'kapila-codigo' ); ?>>
<?php wp_body_open(); ?>

<main class="kapila-pagina">
	<section class="hero">
		<?php if ( $imagem ) : ?>
			<img class="hero__imagem" src="<?php echo esc_url( $imagem ); ?>" alt="">
		<?php endif; ?>

		<h1><?php echo esc_html( kapila_campo( 'titulo', get_the_title() ) ); ?></h1>
		<p class="hero__texto"><?php echo esc_html( kapila_campo( 'subtitulo', 'Texto de apoio da página.' ) ); ?></p>

		<a class="botao" href="<?php echo esc_url( kapila_campo( 'botao_link', home_url( '/' ) ) ); ?>">
			<?php echo esc_html( kapila_campo( 'botao_texto', 'Saiba mais' ) ); ?>
		</a>
	</section>
</main>

<footer class="kapila-rodape">
	<?php echo kapila_credito_html(); // phpcs:ignore WordPress.Security.EscapeOutput -- HTML fixo do tema ?>
</footer>

<?php wp_footer(); ?>
</body>
</html>
