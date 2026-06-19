package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.AuthData;
import com.cle2333.flightattendance.dto.LoginRequest;
import com.cle2333.flightattendance.dto.RegisterRequest;
import com.cle2333.flightattendance.service.AuthService;
import jakarta.validation.Valid;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AuthService auth;

    public AuthController(AuthService auth) {
        this.auth = auth;
    }

    @PostMapping("/register")
    public ApiResponse<AuthData> register(@Valid @RequestBody RegisterRequest req) {
        return ApiResponse.ok(auth.register(req.account(), req.password(), req.nickname()));
    }

    @PostMapping("/login")
    public ApiResponse<AuthData> login(@Valid @RequestBody LoginRequest req) {
        return ApiResponse.ok(auth.login(req.account(), req.password()));
    }
}
