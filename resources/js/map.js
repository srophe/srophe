/* Requires jquery.js and leaflet.js */
/* Javascript for a single item on map */
var terrain = L.tileLayer(
  'http://api.tiles.mapbox.com/v3/sgillies.map-ac5eaoks/{z}/{x}/{y}.png', 
  {attribution: "ISAW, 2012"});

/* Not added by default, only through user control action */
var streets = L.tileLayer(
  'http://api.tiles.mapbox.com/v3/sgillies.map-pmfv2yqx/{z}/{x}/{y}.png', 
  {attribution: "ISAW, 2012"});

var imperium = L.tileLayer(
  'http://pelagios.dme.ait.ac.at/tilesets/imperium//{z}/{x}/{y}.png', {
  attribution: 'Tiles: <a href="http://pelagios-project.blogspot.com/2012/09/a-digital-map-of-roman-empire.html">Pelagios</a>, 2012; Data: NASA, OSM, Pleiades, DARMC',
  maxZoom: 11 });

/* Get marker coordinates from the rel="where" link in the page */
var uri = $('link[rel="where"]').attr("href");
if (uri) {
  var json = unescape(uri.split(',').pop());
  var coords = $.parseJSON(json)['coordinates'];
  var latlng = new L.LatLng(coords[1], coords[0]);
}

var map = L.map('map', {attributionControl: false}).setView(latlng, 5);
L.control.attribution({prefix: false}).addTo(map);

terrain.addTo(map);

L.control.layers({
  "Terrain (default)": terrain,
  "Streets": streets,
  "Imperium": imperium }).addTo(map);

L.marker(latlng).addTo(map);



