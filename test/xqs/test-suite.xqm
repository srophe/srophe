xquery version "3.1";

(:~ This library module contains XQSuite tests for the srophe app.
 :
 : @author Winona Salesky
 : @version 3.0.0
 : @see wsalesky.com
 :)

module namespace tests = "http://syriaca.org//apps/srophe/tests";

import module namespace app = "http://syriaca.org//apps/srophe/templates" at "../../modules/app.xqm";
 
declare namespace test="http://exist-db.org/xquery/xqsuite";


declare variable $tests:map := map {1: 1};

declare
    %test:name('dummy-templating-call')
    %test:arg('n', 'div')
    %test:assertEquals("<p>Dummy templating function.</p>")
    function tests:templating-foo($n as xs:string) as node(){
        app:foo(element {$n} {}, $tests:map)
};
