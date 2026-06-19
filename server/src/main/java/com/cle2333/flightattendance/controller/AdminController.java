package com.cle2333.flightattendance.controller;

import com.cle2333.flightattendance.dto.AdminStats;
import com.cle2333.flightattendance.dto.ApiResponse;
import com.cle2333.flightattendance.dto.LeaderboardEntry;
import com.cle2333.flightattendance.dto.UserDto;
import com.cle2333.flightattendance.service.AdminService;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * ⚠️ 安全说明（与原 Node.js 后端行为一致 —— 详见 README）：
 * 旧版 admin 路由没有任何鉴权（admin.html 里的"登录"是纯前端校验）。
 * 这里的实现沿用了同样的策略，以便现有 admin.html 不需要改动。
 * 上线前应在此处加鉴权（Basic Auth / 单独 JWT / 内网白名单）。
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService admin;

    public AdminController(AdminService admin) {
        this.admin = admin;
    }

    @GetMapping("/users")
    public ApiResponse<List<UserDto>> listUsers() {
        return ApiResponse.ok(admin.listUsers());
    }

    @DeleteMapping("/users/{id}")
    public ApiResponse<Void> deleteUser(@PathVariable Long id) {
        admin.deleteUser(id);
        return ApiResponse.ok(null);
    }

    @GetMapping("/leaderboard")
    public ApiResponse<List<LeaderboardEntry>> leaderboard(
            @RequestParam(required = false, defaultValue = "all") String type) {
        return ApiResponse.ok(admin.leaderboard(type));
    }

    @GetMapping("/users/{id}")
    public ApiResponse<AdminService.UserDetail> getUserDetail(@PathVariable Long id) {
        return ApiResponse.ok(admin.getUserDetail(id));
    }

    @GetMapping("/stats")
    public ApiResponse<AdminStats> stats() {
        return ApiResponse.ok(admin.stats());
    }
}
