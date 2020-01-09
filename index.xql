xquery version "3.1";

module namespace idx="http://www.existsolutions.com/vangogh/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace vg="http://www.vangoghletters.org/ns/";

declare variable $idx:MONTHS := map {
    "January": "01",
    "February": "02",
    "March": "03",
    "April": "04",
    "May": "05",
    "June": "06",
    "July": "07",
    "August": "08",
    "September": "09",
    "October": "10",
    "November": "11",
    "December": "12"
};

declare function idx:parse-date($date as xs:string) {
    if (matches($date, "^\s*\w+,\s*\d+\s+\w+\s+\d+$")) then
        let $parsed := analyze-string($date, "^\s*\w+,\s*(\d+)\s+(\w+)\s+(\d+)$")
        let $day := format-number($parsed//fn:group[1]/number(), "00")
        return
            ``[`{$parsed//fn:group[3]}`-`{$idx:MONTHS($parsed//fn:group[2])}`-`{$day}`]``
    else if (matches($date, "\d{4}")) then
        replace($date, "^.*(\d{4}).*$", "$1") || "-01-01"
    else
        xs:date("1970-01-01")
};

declare function idx:extract-date($date as xs:string?) {
    if ($date) then
        if (matches($date, "^\s*(?:on or )?about ")) then
            idx:parse-date(replace($date, "^\s*(?:on or )?about(.*)", "$1"))
        else if (matches($date, "^.*(and|or)")) then
            idx:parse-date(replace($date, "^.*(?:and|or)(?:\s*about\s*)?(.*)$", "$1"))
        else
            idx:parse-date($date)
    else
        xs:date("1970-01-01")
};


declare function idx:get-metadata($root as element(), $field as xs:string) {
    switch ($field)
        case "title" return
            let $header := $root/tei:teiHeader
            return
                head((
                    $header//tei:msDesc/tei:head, $header//tei:titleStmt/tei:title[@type = 'main'],
                    $header//tei:titleStmt/tei:title
                ))
        case "from" return
            $root//tei:sourceDesc/vg:letDesc/vg:letHeading/tei:author
        case "to" return
            $root//tei:sourceDesc/vg:letDesc/vg:letHeading/vg:addressee
        case "place" return
            $root//tei:sourceDesc/vg:letDesc/vg:letHeading/vg:placeLet
        case "language" return
            ($root/@xml:lang/string(), $root/tei:teiHeader/@xml:lang/string(), "en")[1]
        case "date" return (
            idx:extract-date($root//tei:sourceDesc/vg:letDesc/vg:letHeading/vg:dateLet)
        )[1]
        default return
            ()
};
