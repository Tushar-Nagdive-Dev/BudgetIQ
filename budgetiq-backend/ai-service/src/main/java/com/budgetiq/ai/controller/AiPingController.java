package com.budgetiq.ai.controller;

import com.budgetiq.common.web.ApiResponse;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class AiPingController {

    @GetMapping("/ai/ping")
    ApiResponse<String> ping() {
        return ApiResponse.ok("ai-ok");
    }
}
