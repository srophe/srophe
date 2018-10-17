// Script for dynamically changing sort order 
$( document ).ready(function() {
    var URL = $(location).attr('href');
    $('#date').click( function(event) {
        event.preventDefault();
        $('#events-list').load(URL +  "&sort=date #events-list");
    });
    $('#manuscript').click( function(event) {
        event.preventDefault();
        $('#events-list').load(URL + "&sort=manuscript #events-list");
    });
});