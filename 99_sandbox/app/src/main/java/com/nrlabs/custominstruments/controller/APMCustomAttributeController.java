package com.nrlabs.custominstruments.controller;

import java.util.HashMap;
import java.util.Map;

import com.newrelic.api.agent.NewRelic;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class APMCustomAttributeController {

    @RequestMapping("/apm_custom_attribute")
    public String apm_custom_attribute() {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }
        // https://docs.newrelic.com/docs/agents/java-agent/configuration/java-agent-configuration-config-file#cfg-browser-attributes-enabled
        // https://docs.newrelic.com/docs/agents/manage-apm-agents/agent-data/collect-custom-attributes
        Map<String, Object> m = new HashMap<String, Object>();
        m.put("attr1", "val1");
        m.put("attr2", "val2");
        m.put("attr3", 3);
        m.put("attr4", 4);
        NewRelic.addCustomParameters(m);

        return "apm_custom_attribute";
    }
}
