package com.nrlabs.custominstruments.controller;

import java.util.HashMap;
import java.util.Map;
import java.util.Random;

import com.newrelic.api.agent.NewRelic;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class APMCustomAttributeController {

    @RequestMapping("/apm_custom_attribute")
    public String apm_custom_attribute(@RequestParam("name") String name) {
        try {   
            Random rnd = new Random(System.currentTimeMillis());
            Thread.sleep(1000 * rnd.nextInt(name.length()));
        } catch (Exception e) {
            throw new Error(e);
        }        

        NewRelic.addCustomParameter("attr_name", name);

        return "apm_custom_attribute";
    }


    @RequestMapping(path="/apm_custom_attribute_post", method=RequestMethod.POST)
    public String api_post(@RequestBody String body) {
        NewRelic.addCustomParameter("post_params", body);
        try {   
            Thread.sleep(3000L);
        } catch (Exception e) {
            throw new Error(e);
        }        
        return "apm_custom_attribute";
    }
}


