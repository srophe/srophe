xquery version "3.0";

module namespace teiDocs = "http://syriaca.org/teiDocs";

declare namespace functx = "http://www.functx.com";
declare namespace tei = "http://www.tei-c.org/ns/1.0";
declare namespace xs = "http://www.w3.org/2001/XMLSchema";

(: Adapted from Priscilla Walmsley's functx:path-to-node :)
declare function teiDocs:path-to-node($nodes as node()*) as xs:string* {
    functx:sort($nodes/*/name(.))
};
 
declare function functx:distinct-element-paths($nodes as node()*) as xs:string* {
    distinct-values(teiDocs:path-to-node($nodes/descendant-or-self::*))
};
 
declare function functx:sort($seq as item()*) as item()* {
  for $item in $seq
  order by $item
  return $item
};

declare function teiDocs:get-docs-url($element as xs:string) as xs:string? {
    "http://www.tei-c.org/release/doc/tei-p5-doc/en/html/ref-" || $element || ".html"
};

declare function teiDocs:get-docs-desc($element as xs:string) as xs:string? {
    let $doc := fn:doc("tei_all.xsd")
    return $doc//xs:element[@name = $element]/xs:annotation/xs:documentation/text()
};

declare function teiDocs:extract-paths($nodes as node()*) as element(div)* {
    let $elements := functx:distinct-element-paths($nodes)
    for $element in $elements
    let $docs-url := teiDocs:get-docs-url($element)
    let $docs-desc := teiDocs:get-docs-desc($element)
    return <div class="col-md-12 teiDocs"><div class="col-md-3"><a href="{$docs-url}">{$element}</a></div><div class="col-md-9">{$docs-desc}</div></div>
};

declare function teiDocs:extract-attributes($nodes as node()*) as element(div)* {
    let $attributes := distinct-values($nodes//@*/name(.))
    for $attribute in $attributes
    let $docs-url := teiDocs:get-docs-url($attribute)
    let $docs-desc := teiDocs:get-docs-desc($attribute)
    order by $attribute
    return 
    <div class="col-md-12 teiDocs"><div class="col-md-3"><a href="#">{$attribute}</a></div><div class="col-md-9">{$docs-desc}</div></div>
};


declare function teiDocs:generate-docs($doc as xs:string?) {
<div>
<h4>Elements</h4>
<div>
    {for $teiDoc in teiDocs:extract-paths(fn:doc($doc)) return <div class="row">{$teiDoc}<br /></div>}
</div>
<h4>Attributes</h4>
<div>
    {for $teiDoc in teiDocs:extract-attributes(fn:doc($doc)) return <div class="row">{$teiDoc}<br /></div>}
</div>
</div>     
};
