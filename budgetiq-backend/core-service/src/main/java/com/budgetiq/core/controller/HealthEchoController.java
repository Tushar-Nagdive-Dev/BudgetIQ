package com.budgetiq.core.controller;

import com.budgetiq.common.web.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthEchoController {

    @GetMapping("/api/ping")
    ApiResponse<String> ping() {
        return ApiResponse.ok("core-ok");
    }
}
