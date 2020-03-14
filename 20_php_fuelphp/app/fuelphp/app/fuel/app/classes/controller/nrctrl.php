<?php

class Controller_Nrctrl extends Controller
{ 
  public function action_index(){
    $view = View::forge('nrview.php');
    $view->set('comment', 'This method index with nothing');
    return $view;
  }

  public function action_function1(){
    Request::forge('nrmod/module/exec', false)->execute();

    $this->donothing_inner1();
    
    $view = View::forge('nrview.php');
    $view->set('comment', 'This is Controller_Nrctrl::action_function1');
    
    return $view;
  }

  public function action_function2(){
    Request::forge('nrmod/module/exec', false)->execute();

    $this->donothing_inner1();
      
    $view = View::forge('nrview.php');
    $view->set('comment', 'This is This is Controller_Nrctrl::action_function2');
    
    return $view;
  }

  public function action_function3(){
    sleep(1);
    
    $view = View::forge('nrview.php');
    $view->set('comment', 'This method (action_donothing) do nothing');
    $this->donothing_inner1();
    $this->donothing_inner2();
    $this->donothing_inner3();
    
    return $view;
  }

  public function donothing_inner1() {
    $this->donothing_inner2();
    sleep(1);
  }

  public function donothing_inner2() {
    $this->donothing_inner3();
    sleep(1);
  }
  public function donothing_inner3() {
    sleep(1);
  }

}