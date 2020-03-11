package com.nrlabs.custominstruments.controller;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import com.newrelic.api.agent.NewRelic;
import com.newrelic.api.agent.Trace;

import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.DefaultResponseErrorHandler;
import org.springframework.web.client.RestTemplate;

@RestController
public class ApiController {

    @RequestMapping(path="/api", method=RequestMethod.GET)
    public Object api(@RequestParam("result") String result, @RequestParam(name="count", required=false, defaultValue="0") Integer count) {
        return this.api_nested(result, count);
    }
    
    @Trace
    protected Object api_nested(String result, Integer count) {
        return this.api_nested2(result, count);
    }

    @Trace
    protected Object api_nested2(String result, Integer count) {
        return this.api_nested3(result, count);
    }

    @Trace
    protected Object api_nested3(String result, Integer count) {
        try {
            Thread.sleep(1000L);
        } catch (Exception e) {
            throw new Error(e);
        }

        NewRelic.addCustomParameter("result", result);
        NewRelic.addCustomParameter("count", count);
        
        HttpHeaders headers = new HttpHeaders();
        HttpStatus status;
        String message;
        if (0 == count) {
            if ("success".equals(result)) {
                status = HttpStatus.OK;
                message = "API call succeeded";
            } else {
                status = HttpStatus.BAD_REQUEST;
                message = "Invalid: api error";
            }    
            return new ResponseEntity<>(message, headers, status);
        } else {
            count--;

            RestTemplate restTemplate = new RestTemplate();
            //restTemplate.setErrorHandler(new CustomErrorHandler());

            Map<String, Object> uriVariables = new HashMap<String, Object>();
            uriVariables.put("result", result);
            uriVariables.put("count", count);
        
            return restTemplate.getForEntity("http://localhost:8080/api?result={result}&count={count}", String.class, uriVariables);
        }
    }

    public static class CustomErrorHandler extends DefaultResponseErrorHandler { // (1)

        @Override
        public void handleError(ClientHttpResponse response) throws IOException {
            //Don't throw Exception.
        }
    
    }
}
