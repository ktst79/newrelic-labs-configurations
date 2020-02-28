package com.nrlabs.custominstruments.controller;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import com.newrelic.api.agent.Trace;

@Controller
public class APMCustomInstrumentationController {

    @RequestMapping("/apm_custom_instrumentation")
    public String nested_method() {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        return new NestedController2().nested_method("apm_custom_instrumentation");
    }
}

class NestedController2 {
    public String nested_method(String rtn) {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        return new NestedController3().nested_method(rtn);
    }
}

class NestedController3 {
    @Trace
    public String nested_method(String rtn) {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        return rtn;
    }
}
