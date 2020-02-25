package com.nrlabs.custominstruments.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class APMExceptionController {

    @RequestMapping("/apm_exception")
    public String throw_exception() {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        if (true) {
            throw new Error("APM Exception");
        }
        return "";
    }
}
