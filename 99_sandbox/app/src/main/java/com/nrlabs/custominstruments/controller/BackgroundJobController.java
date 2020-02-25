package com.nrlabs.custominstruments.controller;

import com.newrelic.api.agent.Trace;

import org.apache.commons.logging.Log;
import org.apache.commons.logging.LogFactory;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Controller;

@Controller
public class BackgroundJobController {

    static Log log = LogFactory.getLog(BackgroundJobController.class);

    @Scheduled(fixedDelay = 1000 * 60) // Run every minute
    @Trace(dispatcher = true)
    public void job() {
        log.info("Start Background Job");
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        new NestedBackgroundJobController2().nested_method();
        log.info("End Background Job");
    }
}

class NestedBackgroundJobController2 {
    @Trace
    public void nested_method() {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        new NestedBackgroundJobController3().nested_method();
    }
}

class NestedBackgroundJobController3 {
    @Trace
    public void nested_method() {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
    }
}
