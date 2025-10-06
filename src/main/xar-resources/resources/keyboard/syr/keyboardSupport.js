/*
 * Adds a virtual keyboard to a text input field. The virtual keyboard with these extenstions
 * are known to work on Chrome, Firefox, and Safari running on Windows and iOS and on iOS and
 * Android mobile devices. In mobile environments the native keyboard will be suppressed.
 * 
 * Parameters:
 * 
 * 	textBoxId - Id of the text input field to which the keyboard should be attached
 * 
 * 	layout - Layout that the keyboard should use
 * 
 * 	buttonId (optional) - Id of the DOM object to which a CLICK event handler will be attached 
 * 		for poping up the keyboard. This DOM object will be hidden when the keyboard is visible to
 * 		reduce interactions with the keyboard and causing subtle bugs. If this parameter is missing
 * 		or "falsy" then the keyboard will popup when the text input field receives focus.
 * 
 * 	autocompleteUri (optional) - A URI that is compatible with the JQuery UI autocomplete widget.
 * 		If this parameter is specified then a JQuery UI autocomplete widget will be attached to
 * 		the text input field and will interact with the virtual keyboard. If the parameter is
 * 		missing or "falsy" then a JQuery UI autocomplete widget will not be attached.
 * 
 *  selectionCallback (optional) - If a JQuery UI autocomplete widget was attached to the text input
 *  	field then this callback, if specified, will be called when the user selects an item from
 *  	the autocomplete dropdown list.
 *  
 *  changeCallback (optional) - If a JQuery UI autocomplete widget was attached to the text input
 *  	field then this callback, if specified, will be called when the user changes selection in
 *  	the autocomplete dropdown list.
 *  
 *  Examples:
 * <link rel="stylesheet" href="./css/keyboard.css" type="text/css" media="all" />
 * <link rel="stylesheet" href="./css/keyboard-previewkeyset.css" type="text/css" media="all" />
 * 
 * <script src='./js/jquery.cookie.js'></script>
 * <script src='./js/jquery.keyboard.js'></script>
 * <script src='./js/jquery.keyboard.extension-mobile.js'></script>
 * <script src='./js/jquery.keyboard.extension-navigation.js'></script>
 * <script src='./js/jquery.keyboard.extension-autocomplete.js'></script>
 * <script src='./js/jquery.keyboard.syriac.js'></script>
 * <script src='./js/keyboardSupport.js'></script>
 * 
 * // Add a keyboard with a button to popup the keyboard
 * initializeKeyboard('#lexeme', getKeyboardLayout, '#lexeme-keyboard');
 *  
 * // Add a keyboard with a button to popup the keyboard with an autocomplete widget attached
 * initializeKeyboard('#lexeme', getKeyboardLayout, '#lexeme-keyboard',  Routing.generate('listlexemes'), onSelection);
 *  
 * // Add a keyboard that will popup when the text input box gets focus
 * initializeKeyboard('#lexeme', getKeyboardLayout);
 *  
 * // Add a keyboard that will popup when the text input box gets focus with an autocomplete widget attached
 * initializeKeyboard('#lexeme', getKeyboardLayout, null, Routing.generate('listlexemes'), onSelection);
 */
function initializeKeyboard(textBoxId, layout, buttonId, autocompleteUri, selectionCallback, changeCallback) {
	var mobile = (navigator.userAgent.toLowerCase().search(/ipad|iphone|android/i) > -1);
	var popupButton = buttonId ? $(buttonId) : false;

	function isFunction(functionToCheck) {
		var getType = {};
		return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
	};

	var fixDirection = function()
	{
		var textBox = $(textBoxId);
		var value = textBox.val();
		var matches = value.match(/[\u0700-\u074F]/g);

		if (matches)
		{
			textBox.css('text-align', 'right');
			textBox.css('direction', 'rtl');
		}
		else
		{
			textBox.css('text-align', 'left');
			textBox.css('direction', 'ltr');
		}
	};

	var keyboardButtonPressed = function(e)
	{
		var textBox = $(textBoxId);
		var text = textBox.val();

		fixDirection();

		if (text && text.length > 1) {
			textBox.autocomplete("search");
		}
	};

	var renderListItem = function(ul, item) {
		return $('<li></li>')
			.data('item.autocomplete', item)
			.append('<a>' + item.label + '</a>')
			.appendTo(ul);
	};

	var attachAutoComplete = function () {
		var textBox = $(textBoxId);

		var options = { 
			source: autocompleteUri, 
			minLength: 2, 
			delay: 500,
			autoFocus: true
		};

		if (isFunction(selectionCallback)) options.select = selectionCallback;
		if (isFunction(changeCallback)) options.change = changeCallback;

		$(textBox).autocomplete(options).data("ui-autocomplete")._renderItem = renderListItem;
	};

	var getKeyboard = function(close) {
		var textBox = $(textBoxId);
		return (isFunction(textBox.getkeyboard) ? textBox.getkeyboard() : false);
	};

	var createKeyboard = function() {
		var textBox = $(textBoxId);
		var keyboardLayout = isFunction(layout) ? layout() : layout;
		var options = {
			stayOpen : false,
			layout : keyboardLayout,
			usePreview: false,
			autoAccept: true,
			autoAcceptOnEsc: true,
			useWheel: false,
			lockInput : mobile,
			beforeVisible: function (e, keyboard, el) {
	            keyboard.el.blur();
	        },
	        position: {
            // null = attach to input/textarea;
            // use $(sel) to attach elsewhere
            of: null,
            my: 'center top',
            at: 'center top',
            // used when "usePreview" is false
            at2: 'center bottom'
            }
		};

		if (popupButton) options.openOn = "";

		textBox.keyboard(options);

		if (autocompleteUri) {
			attachAutoComplete();
		
			textBox.addAutocomplete({
				position : {
					of : textBox,
					my : 'left top',
					at : 'left bottom',
					at2 : 'left bottom',
					collision: 'none'
				}
			});
		}

		var kb = getKeyboard();

		if (popupButton && kb) {
			textBox.on('hidden', function(e){
				var kb = getKeyboard();
				if (kb) {
					removeKeyboard(kb.options.autoAccept ? 'true' : false);
					rebuildTextBox();
					if (autocompleteUri) {
						attachAutoComplete();
					}
				}
				popupButton.prop('hidden', false);
			});

			popupButton.prop('hidden', true);
			kb.reveal();
		}

		if (autocompleteUri) {
			if (mobile) {
				textBox.on('change', autocompleteUri ? keyboardButtonPressed : fixDirection);
				$('button.ui-keyboard-button').on('touch', autocompleteUri ? keyboardButtonPressed : fixDirection);
			} else {
				textBox.on('change', autocompleteUri ? keyboardButtonPressed : fixDirection);
				$('button.ui-keyboard-button').on('click', autocompleteUri ? keyboardButtonPressed : fixDirection);
			}
		}
	};

	var removeKeyboard = function(close) {
		var kb = getKeyboard();

		if (kb) {
			kb.close(close);
			kb.destroy();
		}

		if (popupButton) popupButton.prop('hidden', false);
	};
	
	var rebuildTextBox = function() {
		var textBox = $(textBoxId);
		var t = textBox.clone(false);

		t.insertAfter(textBox);
		textBox.remove();
	};
	
	$.keyboard.keyaction.enter = function() {
		var kb = getKeyboard();

		if (kb) {
			removeKeyboard(kb.options.autoAccept ? 'true' : false);
			rebuildTextBox();
			if (autocompleteUri) {
				attachAutoComplete();
			}
		}

		return false;
	};

	var clickButton = function(e){
		var kb = getKeyboard();
		var isVisible = kb ? kb.isVisible() : false;
		
		if (isVisible) {
			removeKeyboard();
		}

		rebuildTextBox();
		createKeyboard();
	};

	if (popupButton) {
		popupButton.click(clickButton);

		if (autocompleteUri) {
			attachAutoComplete();
		}
	} else {
		createKeyboard();
	}
}