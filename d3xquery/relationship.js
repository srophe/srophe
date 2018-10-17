$(document).ready(function () {
            /* Populate relationsip menu */
            populateRelationships(); 
            
            /* Subimt form */
            $("#query").on('click', function(e){
             e.preventDefault();
             var $form = $("#RDF"),
                url = $form.attr('action'),
                type = $("#type option:selected").val();
                if (type === "JSON" || type === "XML") {
                /* If JSON/XML submit the form with the appropriate/requested format */
                     $("#format").val(type);
                     $('form').submit();
                } else {
                /* Otherwise send to d3 visualization, set format to json.  */
                    $("#format").val('json');
                    $.get(url, $form.serialize(), function(data) {
                       d3sparql.graphType(data, type); 
                       /*console.log(data);*/
                    }).fail( function(jqXHR, textStatus, errorThrown) {
                        console.log(textStatus);
                    });
                }
             });
             
             
            });
            
            /* Toggle textarea */
            function toggle() {
                d3sparql.toggle()
            }
            
            /* Function to populate relationships */
            function populateRelationships(){
                    var $form = $("#RDF")
                    $.get('list-relationships.xql', function(data) {
                        var options = "";
                        var data = data.option
                        // Loop over our returned result set and build our options
                        $.each(data, function(k, v){
                            options += '<option label="' + v.label + '">' + v.value + '</option>';
                        });
                        $("#relationship").append(options);
                    }).fail( function(jqXHR, textStatus, errorThrown) {
                        console.log(textStatus);
                    });
            };