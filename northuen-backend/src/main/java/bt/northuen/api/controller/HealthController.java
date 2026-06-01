package bt.northuen.api.controller;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Instant;
import java.util.Map;

@RestController
public class HealthController {
    @GetMapping("/")
    public Map<String, Object> root() {
        return Map.of(
                "status", "ok",
                "service", "northuen-backend",
                "health", "/api/health",
                "docs", "/swagger-ui/index.html",
                "time", Instant.now().toString()
        );
    }

    @GetMapping("/api/health")
    public Map<String, Object> health() {
        return Map.of(
                "status", "ok",
                "service", "northuen-backend",
                "time", Instant.now().toString()
        );
    }
}
