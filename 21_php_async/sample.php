#!/usr/bin/php

<?php

class A {
    function sub1($a) {
        print("sub1");
        $rt = self::sub2($a + 1);
        sleep(1);
        return $rt;
    }
    
    function sub2($a) {
        print("sub2");
        $rt = self::sub3($a + 1);
        sleep(1);
        return $rt;
    }
    
    function sub3($a) {
        print("sub3");
        $rt = $a + 1;
        call_http();
        sleep(1);
        return $rt;
    }        
}

function loopme($arg_max)
{
    $i = 0;
    $inst = new A();
    while ($i < $arg_max) {
        print($inst::sub1($i));
        sleep(1);
        $i++;
    }    

}

function call_http() {
    $get_url = 'https://www.newrelic.com/';
    $headers = [
        'User-Agent: PHP/' . PHP_VERSION,
    ];
    $opts = [
        'http' => [
            'header' => implode("\r\n", $headers) . "\r\n",
            'content' => null,
        ]
    ];
    $json = file_get_contents($get_url, false, stream_context_create($opts));
    var_dump(json_decode($json, true));
}


function main() {
    $max = 3;
    loopme($max);    
    sleep(3);
}

main();

?>
