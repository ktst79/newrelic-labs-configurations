package com.nrlabs.custominstruments.controller;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;

@RestController
public class ApiController {

    @RequestMapping(path="/api", method=RequestMethod.GET)
    public String api(@RequestParam("result") String result) {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        if ("success".equals(result)) {
            return "API call succeeded";
        } else {
            throw new Error("API call failed");
        }
    }
}
