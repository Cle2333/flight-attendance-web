package com.cle2333.flightattendance;

import com.cle2333.flightattendance.dto.AuthData;
import com.cle2333.flightattendance.dto.LoginRequest;
import com.cle2333.flightattendance.dto.RegisterRequest;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.test.context.ActiveProfiles;
import org.springframework.web.client.RestTemplate;

import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
@ActiveProfiles("test")
class AuthFlowIntegrationTest {

    @LocalServerPort int port;
    @Autowired ObjectMapper json;

    private final RestTemplate http = new RestTemplate();

    private String url(String path) { return "http://localhost:" + port + path; }

    @Test
    void registerLoginRecordsFlow() throws Exception {
        // 1) register
        RegisterRequest reg = new RegisterRequest("alice", "secret123", "Alice");
        HttpHeaders h = new HttpHeaders();
        h.setContentType(MediaType.APPLICATION_JSON);
        ResponseEntity<String> regRes = http.postForEntity(
                url("/api/auth/register"),
                new HttpEntity<>(json.writeValueAsString(reg), h), String.class);
        assertEquals(200, regRes.getStatusCode().value());
        JsonNode regBody = json.readTree(regRes.getBody());
        assertTrue(regBody.get("success").asBoolean());
        String token = regBody.path("data").path("token").asText();
        assertNotNull(token);
        long userId = regBody.path("data").path("userId").asLong();

        // 2) login with same account
        LoginRequest login = new LoginRequest("alice", "secret123");
        ResponseEntity<String> loginRes = http.postForEntity(
                url("/api/auth/login"),
                new HttpEntity<>(json.writeValueAsString(login), h), String.class);
        assertEquals(200, loginRes.getStatusCode().value());
        assertTrue(json.readTree(loginRes.getBody()).get("success").asBoolean());

        // 3) GET /api/records (auth)
        HttpHeaders auth = new HttpHeaders();
        auth.setBearerAuth(token);
        ResponseEntity<String> listRes = http.exchange(
                url("/api/records"), HttpMethod.GET, new HttpEntity<>(auth), String.class);
        assertEquals(200, listRes.getStatusCode().value());
        assertTrue(json.readTree(listRes.getBody()).get("success").asBoolean());

        // 4) no token -> 401 (RestTemplate 对 4xx 抛异常，捕获以读取状态码)
        try {
            http.getForEntity(url("/api/records"), String.class);
            org.junit.jupiter.api.Assertions.fail("expected 401");
        } catch (org.springframework.web.client.HttpStatusCodeException e) {
            assertEquals(401, e.getStatusCode().value());
        }

        // 5) /api/test works without auth
        ResponseEntity<String> ping = http.getForEntity(url("/api/test"), String.class);
        assertEquals(200, ping.getStatusCode().value());
        assertTrue(json.readTree(ping.getBody()).get("success").asBoolean());
    }

    @Test
    void leaderboardIsPublic() {
        // 与原 Node.js 后端行为一致 —— admin 路由不需要鉴权
        ResponseEntity<String> res = http.getForEntity(url("/api/admin/leaderboard?type=all"), String.class);
        assertEquals(200, res.getStatusCode().value());
    }
}
