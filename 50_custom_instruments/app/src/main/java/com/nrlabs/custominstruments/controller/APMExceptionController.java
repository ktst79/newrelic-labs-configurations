package com.nrlabs.custominstruments.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;

@Controller
public class APMExceptionController {

    @RequestMapping("/apm_exception")
    public String throw_exception(@RequestParam("ignore") boolean ignore) throws APMException {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        String msg = ignore ? "Exception is ignored" : "Exception is not ignored";
        if (true) {
            throw new APMException(msg);
        }
        return "";
    }
}
