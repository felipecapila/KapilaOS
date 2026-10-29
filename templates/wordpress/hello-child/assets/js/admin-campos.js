/* Painel: botão "Escolher imagem" dos campos editáveis (biblioteca de mídia do WordPress). */
(function ($) {
	$(document).on('click', '.kapila-imagem-escolher', function (e) {
		e.preventDefault();
		var caixa = $(this).closest('.kapila-imagem');
		var frame = wp.media({ title: 'Escolher imagem', button: { text: 'Usar esta imagem' }, multiple: false, library: { type: 'image' } });

		frame.on('select', function () {
			var anexo = frame.state().get('selection').first().toJSON();
			var url = anexo.sizes && anexo.sizes.medium ? anexo.sizes.medium.url : anexo.url;
			caixa.find('input[type=hidden]').val(anexo.id);
			caixa.find('img').attr('src', url).show();
		});

		frame.open();
	});

	$(document).on('click', '.kapila-imagem-remover', function (e) {
		e.preventDefault();
		var caixa = $(this).closest('.kapila-imagem');
		caixa.find('input[type=hidden]').val('');
		caixa.find('img').attr('src', '').hide();
	});
})(jQuery);
