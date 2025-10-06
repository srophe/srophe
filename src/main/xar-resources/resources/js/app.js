

$(function(){
    $("div.collapse:not(:visible)").attr("aria-expanded","false");
    $("a[aria-expanded=true]").each(function(){
        var ref = $(this).attr("href");
        $(this).attr("aria-expanded",$(ref).attr("aria-expanded"));
    });
    
    $(".listEntities button[data-toggle=collapse]").each(function(){
        var ref = $(this).attr("href");
        $(ref).attr("style","");
        $(ref).addClass("in");
        $(ref).attr("aria-expanded","true");
        $(this).remove();
    });  
    
    $("#mainMenu .btn-group-justified").removeClass("btn-group-justified");
    
    $("h3.label").remove();
    
    $("#mainMenu .mainMenuContent .collapse .row:first-child").each(function(){
        $(this).parent().addClass("datasliketable");
    });
    $(".datasliketable").each(function(){
        $(this).parents(".datasliketable").removeClass("datasliketable");
    });
    
    $(".actionButtons .btn").removeClass("btn-grey").removeClass("btn-default");
    
    $(".titleStmt .actionButtons").each(function(){
       var enfants = $(this).find("a");
       if (enfants.length == 4) 
       {
           $(enfants[0]).attr("id","icoscan");
           $(enfants[1]).attr("id","icofeedback");
           $(enfants[2]).attr("id","icoxml");
           $(enfants[3]).attr("id","icoprint");
       }
       if (enfants.length == 3) 
       {
           $(enfants[0]).attr("id","icofeedback");
           $(enfants[1]).attr("id","icoxml");
           $(enfants[2]).attr("id","icoprint");
       }
    });
    
    $(".listEntities .whiteBoxwShadow.entityList h4").append('<span class="glyphicon glyphicon-chevron-down"></span>');
    $(".listEntities .whiteBoxwShadow.entityList h4+ul").hide();
    $(".listEntities .whiteBoxwShadow.entityList h4").on("click",function(){
        var monul = $(this).siblings("ul");
        var isdown = false;
        monul.each(function(monindex, monselector){
            if (!$(monselector).is(":hidden")) isdown = true;
        });
        
        if (isdown)
        {
            $(this).find(".glyphicon").removeClass("glyphicon-chevron-up").addClass("glyphicon-chevron-down");
        }
        else
        {
            $(this).find(".glyphicon").removeClass("glyphicon-chevron-down").addClass("glyphicon-chevron-up");
        }
        
        monul.toggle("fast");
    });
});