<?php
/**
 * Campos editáveis das páginas por código, sem plugin (nada de ACF).
 *
 * O cliente edita textos, imagens e links em Páginas → Editar → caixa "Conteúdo da página".
 * A caixa aparece depois que a página é salva com um template que tenha campos aqui.
 *
 * Tipos: texto | textarea | url | imagem
 * No template: kapila_campo( 'chave', 'padrão' ) e kapila_imagem_url( 'chave', 'url padrão' ).
 * Campo vazio = usa o padrão escrito no template (a página nunca fica em branco).
 */

if ( ! defined( 'ABSPATH' ) ) {
	exit;
}

/**
 * Campos por template (chave = nome do arquivo em page-templates/, sem .php).
 */
function kapila_campos_definicoes() {
	return array(
		'pagina-codigo'        => array(
			'titulo'      => array( 'rotulo' => 'Título principal', 'tipo' => 'texto' ),
			'subtitulo'   => array( 'rotulo' => 'Texto de apoio', 'tipo' => 'textarea' ),
			'botao_texto' => array( 'rotulo' => 'Texto do botão', 'tipo' => 'texto' ),
			'botao_link'  => array( 'rotulo' => 'Link do botão', 'tipo' => 'url' ),
			'imagem'      => array( 'rotulo' => 'Imagem de destaque', 'tipo' => 'imagem' ),
		),
		'pagina-codigo-header' => array(
			'titulo'    => array( 'rotulo' => 'Título principal', 'tipo' => 'texto' ),
			'subtitulo' => array( 'rotulo' => 'Texto de apoio', 'tipo' => 'textarea' ),
		),
	);
}

function kapila_campos_do_post( $post_id ) {
	$template = get_page_template_slug( $post_id );
	if ( ! $template || 0 !== strpos( $template, 'page-templates/' ) ) {
		return array();
	}
	$definicoes = kapila_campos_definicoes();
	$nome       = basename( $template, '.php' );
	return isset( $definicoes[ $nome ] ) ? $definicoes[ $nome ] : array();
}

// ------------------------------------------------------------ leitura (templates)

function kapila_campo( $chave, $padrao = '', $post_id = null ) {
	$post_id = $post_id ? $post_id : get_queried_object_id();
	$valor   = get_post_meta( $post_id, '_kapila_' . $chave, true );
	return ( '' === $valor || false === $valor ) ? $padrao : $valor;
}

function kapila_imagem_url( $chave, $padrao = '', $tamanho = 'large', $post_id = null ) {
	$id  = absint( kapila_campo( $chave, 0, $post_id ) );
	$url = $id ? wp_get_attachment_image_url( $id, $tamanho ) : '';
	return $url ? $url : $padrao;
}

// ------------------------------------------------------------ painel

add_action(
	'add_meta_boxes_page',
	function ( $post ) {
		if ( ! kapila_campos_do_post( $post->ID ) ) {
			return;
		}
		add_meta_box( 'kapila-campos', 'Conteúdo da página', 'kapila_campos_caixa', 'page', 'normal', 'high' );
	}
);

function kapila_campos_caixa( $post ) {
	wp_nonce_field( 'kapila_campos_salvar', 'kapila_campos_nonce' );
	echo '<p><em>Página feita por código. Edite o conteúdo aqui, não pelo Elementor. Campo vazio usa o texto padrão.</em></p>';

	foreach ( kapila_campos_do_post( $post->ID ) as $chave => $campo ) {
		$nome  = 'kapila_campos[' . $chave . ']';
		$valor = get_post_meta( $post->ID, '_kapila_' . $chave, true );
		$id    = 'kapila-campo-' . $chave;

		echo '<p><label for="' . esc_attr( $id ) . '"><strong>' . esc_html( $campo['rotulo'] ) . '</strong></label><br>';

		switch ( $campo['tipo'] ) {
			case 'textarea':
				echo '<textarea class="widefat" rows="4" id="' . esc_attr( $id ) . '" name="' . esc_attr( $nome ) . '">' . esc_textarea( $valor ) . '</textarea>';
				break;

			case 'url':
				echo '<input type="url" class="widefat" id="' . esc_attr( $id ) . '" name="' . esc_attr( $nome ) . '" value="' . esc_attr( $valor ) . '">';
				break;

			case 'imagem':
				$preview = $valor ? wp_get_attachment_image_url( absint( $valor ), 'medium' ) : '';
				echo '<span class="kapila-imagem">';
				echo '<input type="hidden" id="' . esc_attr( $id ) . '" name="' . esc_attr( $nome ) . '" value="' . esc_attr( $valor ) . '">';
				echo '<img src="' . esc_url( $preview ) . '" alt="" style="max-width:240px;height:auto;display:' . ( $preview ? 'block' : 'none' ) . ';margin:6px 0">';
				echo '<button type="button" class="button kapila-imagem-escolher">Escolher imagem</button> ';
				echo '<button type="button" class="button-link kapila-imagem-remover">Remover</button>';
				echo '</span>';
				break;

			default:
				echo '<input type="text" class="widefat" id="' . esc_attr( $id ) . '" name="' . esc_attr( $nome ) . '" value="' . esc_attr( $valor ) . '">';
		}

		echo '</p>';
	}
}

add_action(
	'save_post_page',
	function ( $post_id ) {
		if ( ! isset( $_POST['kapila_campos_nonce'] ) || ! wp_verify_nonce( sanitize_key( wp_unslash( $_POST['kapila_campos_nonce'] ) ), 'kapila_campos_salvar' ) ) {
			return;
		}
		if ( ( defined( 'DOING_AUTOSAVE' ) && DOING_AUTOSAVE ) || ! current_user_can( 'edit_page', $post_id ) ) {
			return;
		}

		$enviados = isset( $_POST['kapila_campos'] ) && is_array( $_POST['kapila_campos'] ) ? wp_unslash( $_POST['kapila_campos'] ) : array();

		foreach ( kapila_campos_do_post( $post_id ) as $chave => $campo ) {
			$bruto = isset( $enviados[ $chave ] ) ? $enviados[ $chave ] : '';

			switch ( $campo['tipo'] ) {
				case 'textarea':
					$valor = sanitize_textarea_field( $bruto );
					break;
				case 'url':
					$valor = esc_url_raw( $bruto );
					break;
				case 'imagem':
					$valor = absint( $bruto ) ? absint( $bruto ) : '';
					break;
				default:
					$valor = sanitize_text_field( $bruto );
			}

			if ( '' === $valor ) {
				delete_post_meta( $post_id, '_kapila_' . $chave );
			} else {
				update_post_meta( $post_id, '_kapila_' . $chave, $valor );
			}
		}
	}
);
