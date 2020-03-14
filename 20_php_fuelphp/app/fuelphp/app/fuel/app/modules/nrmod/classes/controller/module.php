<?php

namespace nrmod;

class Controller_Module extends \Controller
{
    public function action_exec(){
        sleep(1);
        $this->inner1();
        $this->inner2();
        $this->inner3();
    }

    public function inner1() {
        sleep(1);
        $this->inner2();
    }

    public function inner2() {
        sleep(1);
        $this->inner3();
    }
    public function inner3() {
        sleep(1);
    }

}
