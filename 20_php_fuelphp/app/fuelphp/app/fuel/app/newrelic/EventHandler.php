<?php
namespace Newrelic;

class EventHandler
{
    public static function register()
    {
        if(!extension_loaded('newrelic')) {
            return;
        }
        
        \Event::Register("controller_started", "\Newrelic\EventHandler::eventControllerStarted");
    }

    public static function eventControllerStarted()
    {
        $request = \Request::active();

        if(strpos($request->controller,'Nrmod') === false){
            # Specify transaction name only when top level controller (exclude controllers defined as module)
            newrelic_name_transaction($request->controller . '\\' . $request->action);
        }
    }
}
