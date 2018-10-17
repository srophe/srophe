xquery version "3.0";

module namespace maps = "http://syriaca.org/srophe/maps";

(:~
 : Module builds leafletjs maps and/or Google maps
 : Pulls geoJSON from http://syriaca.org/geojson module. 
 : 
 : @author Winona Salesky <wsalesky@gmail.com>
 : @authored 2014-06-25
:)
import module namespace geojson = "http://syriaca.org/srophe/geojson" at "../content-negotiation/geojson.xqm";
import module namespace config="http://syriaca.org/srophe/config" at "../config.xqm";

declare namespace tei = "http://www.tei-c.org/ns/1.0";

(:~
 : Selects map rendering based on config.xml entry
:)
declare function maps:build-map($nodes as node()*, $total-count as xs:integer?){
if($config:app-map-option = 'google') then maps:build-google-map($nodes)
else maps:build-leaflet-map($nodes,$total-count)
};

(:~
 : Build leafletJS map
:)
declare function maps:build-leaflet-map($nodes as node()*, $total-count as xs:integer?){
    <div id="map-data" style="margin-bottom:3em;">
        <script type="text/javascript" src="{$config:nav-base}/resources/leaflet/leaflet.js"/>
        <script type="text/javascript" src="{$config:nav-base}/resources/leaflet/leaflet.awesome-markers.min.js"/>
        <!--
        <script src="http://isawnyu.github.com/awld-js/lib/requirejs/require.min.js" type="text/javascript"/>
        <script src="http://isawnyu.github.com/awld-js/awld.js?autoinit" type="text/javascript"/>
        -->
        <div id="map"/>
        {
            if($total-count gt 0) then 
               <div class="hint map pull-right small">
                * This map displays {count($nodes)} records. Only places with coordinates are displayed. 
                     <button class="btn btn-default btn-sm" data-toggle="modal" data-target="#map-selection" id="mapFAQ">See why?</button>
               </div>
            else ()
            }
        <script type="text/javascript">
            <![CDATA[
            var terrain = L.tileLayer('http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', {attribution: "ISAW, 2012"});
                                
            /* Not added by default, only through user control action */
            var streets = L.tileLayer('http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', {attribution: "ISAW, 2012"});
                                
            var imperium = L.tileLayer('http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {attribution: 'Tiles: &lt;a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html"&gt;Pelagios&lt;/a&gt;, 2012; Data: NASA, OSM, Pleiades, DARMC', maxZoom: 11 });
                                
            var placesgeo = ]]>{geojson:geojson($nodes)}
            <![CDATA[                                
            var sropheIcon = L.Icon.extend({
                                            options: {
                                                iconSize:     [35, 35],
                                                iconAnchor:   [22, 94],
                                                popupAnchor:  [-3, -76]
                                                }
                                            });
                                            var redIcon =
                                                L.AwesomeMarkers.icon({
                                                    icon:'glyphicon-flag',
                                                    markerColor: 'red'
                                                }),
                                            orangeIcon =  
                                                L.AwesomeMarkers.icon({
                                                    icon:'glyphicon-flag',
                                                    markerColor: 'orange'
                                                }),
                                            purpleIcon = 
                                                L.AwesomeMarkers.icon({
                                                    icon:'glyphicon-flag',
                                                    markerColor: 'purple'
                                                }),
                                            blueIcon =  L.AwesomeMarkers.icon({
                                                    icon:'glyphicon-flag',
                                                    markerColor: 'blue'
                                                });
                                        
            var geojson = L.geoJson(placesgeo, {onEachFeature: function (feature, layer){
                            var typeText 
                            var popupContent = 
                                "<a href='" + feature.properties.uri + "' class='map-pop-title'>" +
                                feature.properties.name + "</a>" + (feature.properties.type ? "Type: " + typeText : "") +
                                (feature.properties.desc ? "<span class='map-pop-desc'>"+ feature.properties.desc +"</span>" : "");
                                layer.bindPopup(popupContent);
        
                                switch (feature.properties.type) {
                                    case 'born-at': return layer.setIcon(orangeIcon);
                                    case 'syriaca:bornAt' : return layer.setIcon(orangeIcon);
                                    case 'died-at':   return layer.setIcon(redIcon);
                                    case 'syriaca:diedAt' : return layer.setIcon(redIcon);
                                    case 'has-literary-connection-to-place':   return layer.setIcon(purpleIcon);
                                    case 'syriaca:hasLiteraryConnectionToPlace' : return layer.setIcon(purpleIcon);
                                    case 'has-relation-to-place':   return layer.setIcon(blueIcon);
                                    case 'syriaca:hasRelationToPlace' :   return layer.setIcon(blueIcon);
                                    default : '';
                                 }               
                                }
                            })
        var map = L.map('map').fitBounds(geojson.getBounds(),{maxZoom: 5});     
        terrain.addTo(map);
                                        
        L.control.layers({
                        "Terrain (default)": terrain,
                        "Streets": streets,
                        "Imperium": imperium }).addTo(map);
        geojson.addTo(map);     
        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};

(:~
 : Build Google maps
:)
declare function maps:build-google-map($nodes as node()*){
    <div id="map-data" style="margin-bottom:3em;">
        <script src="http://maps.googleapis.com/maps/api/js">//</script>
        <div id="map"/>
        <div class="hint map pull-right">* {count($nodes)} have coordinates and are shown on this map. 
             <button class="btn btn-link" data-toggle="modal" data-target="#map-selection" id="mapFAQ">Read more...</button>
        </div>
    
        <script type="text/javascript">
            <![CDATA[
            var map;
                            
            var bounds = new google.maps.LatLngBounds();
            
            function initialize(){
                map = new google.maps.Map(document.getElementById('map'), {
                    center: new google.maps.LatLng(0,0),
                    mapTypeId: google.maps.MapTypeId.TERRAIN
                });

                var placesgeo = ]]>{geojson:geojson($nodes)}
                <![CDATA[ 
                
                var infoWindow = new google.maps.InfoWindow();
                
                for(var i = 0, length = placesgeo.features.length; i < length; i++) {
                    var data = placesgeo.features[i]
                    var coords = data.geometry.coordinates;
                    var latLng = new google.maps.LatLng(coords[1],coords[0]);
                    var marker = new google.maps.Marker({
                        position: latLng,
                        map:map
                    });
                    
                    // Creating a closure to retain the correct data, notice how I pass the current data in the loop into the closure (marker, data)
         			(function(marker, data) {
         
         				// Attaching a click event to the current marker
         				google.maps.event.addListener(marker, "click", function(e) {
         					infoWindow.setContent("<a href='" + data.properties.uri + "'>" + data.properties.name + " - " + data.properties.type + "</a>");
         					infoWindow.open(map, marker);
         				});
         
         
         			})(marker, data);
                    bounds.extend(latLng);
                }
                
                map.fitBounds(bounds);
                // Adjusts zoom for single items on the map
                google.maps.event.addListenerOnce(map, 'bounds_changed', function(event) {
                  if (this.getZoom() > 10) {
                    this.setZoom(10);
                  }
                });
            }

            google.maps.event.addDomListener(window, 'load', initialize)

        ]]>
        </script>
         <div>
            <div class="modal fade" id="map-selection" tabindex="-1" role="dialog" aria-labelledby="map-selectionLabel" aria-hidden="true">
                <div class="modal-dialog">
                    <div class="modal-content">
                        <div class="modal-header">
                            <button type="button" class="close" data-dismiss="modal">
                                <span aria-hidden="true"> x </span>
                                <span class="sr-only">Close</span>
                            </button>
                        </div>
                        <div class="modal-body">
                            <div id="popup" style="border:none; margin:0;padding:0;margin-top:-2em;"/>
                        </div>
                        <div class="modal-footer">
                            <a class="btn" href="/documentation/faq.html" aria-hidden="true">See all FAQs</a>
                            <button type="button" class="btn btn-default" data-dismiss="modal">Close</button>
                        </div>
                    </div>
                </div>
            </div>
         </div>
         <script type="text/javascript">
         <![CDATA[
            $('#mapFAQ').click(function(){
                $('#popup').load( '../documentation/faq.html #map-selection',function(result){
                    $('#map-selection').modal({show:true});
                });
             });]]>
         </script>
    </div> 
};
