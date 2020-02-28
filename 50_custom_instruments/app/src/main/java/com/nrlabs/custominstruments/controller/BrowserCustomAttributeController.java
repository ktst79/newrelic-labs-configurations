package com.nrlabs.custominstruments.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class BrowserCustomAttributeController {

    @RequestMapping("/browser_custom_attribute")
    public String browser_custom_attribute() {
        return "browser_custom_attribute";
    }
}
