$(function(){
    $(window).scroll(function() {
        if ($("body.homepage").length > 0) {
            var Headerheight = $("#homecomm > .navbar").outerHeight();
            var topOfWindow = $(window).scrollTop();
            console.log(topOfWindow," ",Headerheight);
            if (topOfWindow > Headerheight) {$("#navbarhome").show("fast");}
            if (topOfWindow <= Headerheight) {$("#navbarhome").hide("fast");}
        }
    });
});
