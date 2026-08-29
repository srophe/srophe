$(document).ready(function() {
// Main javascript functions used by place pages
// validate contact forms
$.validator.setDefaults({
	submitHandler: function() {
	   if($('input#url').val().length == 0)
         { 
       	//Ajax submit for contact form
           $.ajax({
                   type:'POST', 
                   url: $('#email').attr('action'), 
                   data: $('#email').serializeArray(),
                   dataType: "html", 
                   success: function(response) {
                       var temp = response;
                       if(temp == 'Recaptcha fail') {
                           alert('please try again');
                           Recaptcha.reload();
                       }else {
                           $('div#modal-body').html(temp);
                           $('#email-submit').hide();
                           $('#email')[0].reset();
                       }
                      // $('div#modal-body').html(temp);
               }});
        }
        return false;
	}
});

$("#email").validate({
		rules: {
			recaptcha_challenge_field: "required",
			name: "required",
			email: {
				required: true,
				email: true
			},
			subject: {
				required: true,
				minlength: 2
			},
			comments: {
				required: true,
				minlength: 2
			}
		},
		messages: {
			name: "Please enter your name",
            subject: "Please enter a subject",
			comments: "Please enter a comment",
			email: "Please enter a valid email address",
			recaptcha_challenge_field: "Captcha helps prevent spamming. This field cannot be empty"
		}
});

//Expand works authored-by in persons page
$('a.getData').click(function(event) {
    event.preventDefault();
    var title = $(this).data('label');
    var URL = $(this).data('ref');
    $("#moreInfoLabel").text(title);
    $('#moreInfo-box').load(URL + " #search-results");
});
    
$('#showSection').click(function(event) {
    event.preventDefault();
    $('#recComplete').load('/exist/apps/srophe/documentation/faq.html #selection');
});

//Changes text on toggle buttons, toggle funtion handled by Bootstrap
$('.togglelink').click(function(e){
    e.preventDefault();
    var el = $(this);
    if (el.text() == el.data("text-swap")) {
          el.text(el.data("text-original"));
        } else {
          el.data("text-original", el.text());
          el.text(el.data("text-swap"));
        }
});           

//Load dynamic content
$('.dynamicContent').each(function(index, element) { 
    var url = $(this).data('url');
    var current = $(this) 
    $.get(url, function(data) {
        $(current).html(data);    
    }); 
   });

//hide spinner on load
$('.spinning').hide();

//Load dynamic content
$('.getContent').click(function(index, element) { 
    var url = $(this).data('url');
    var current = $(this) 
    $('.spinning').show();
    $.get(url, function(data) {
        $(current).html(data);
        $('.spinning').hide();
        console.log('Getting data...')
    }); 
   });
   
if (navigator.appVersion.indexOf("Mac") > -1 || navigator.appVersion.indexOf("Linux") > -1) {
    $('.get-syriac').show();
}

$(function () {
  $('[data-toggle="tooltip"]').tooltip()
})

//Clipboard function for any buttons with clipboard class. Uses clipboard.js
var clipboard = new Clipboard('.clipboard');

clipboard.on('success', function(e) {
    console.info('Action:', e.action);
    console.info('Text:', e.text);
    console.info('Trigger:', e.trigger);
    e.clearSelection();
});

clipboard.on('error', function(e) {
    console.error('Action:', e.action);
    console.error('Trigger:', e.trigger);
});

//add active class to browse tabs
var params = window.location.search;
if(params !== 'undefined' && params !== ''){
    $('.nav-tabs a[href*="' + params + '"]').parents('li').addClass('active');
} else {
    $('.nav-tabs li').first().addClass('active');
}

});