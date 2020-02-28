package com.nrlabs.custominstruments.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class RootController {

    @RequestMapping("/")
    public String index() {
        return "index";
    }

    @RequestMapping("/ajax")
    public String ajax(@RequestParam("result") String result) {
        if ("success".equals(result)) {
            return "ajax_success";
        } else {
            return "ajax_failure";
        }
    }
}
