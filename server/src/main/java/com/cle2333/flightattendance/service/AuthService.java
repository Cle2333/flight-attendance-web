package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.AuthData;
import com.cle2333.flightattendance.entity.Settings;
import com.cle2333.flightattendance.entity.User;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.SettingsRepository;
import com.cle2333.flightattendance.repository.UserRepository;
import com.cle2333.flightattendance.security.JwtTokenProvider;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AuthService {

    private final UserRepository users;
    private final SettingsRepository settings;
    private final PasswordEncoder encoder;
    private final JwtTokenProvider jwt;

    public AuthService(UserRepository users,
                       SettingsRepository settings,
                       PasswordEncoder encoder,
                       JwtTokenProvider jwt) {
        this.users = users;
        this.settings = settings;
        this.encoder = encoder;
        this.jwt = jwt;
    }

    @Transactional
    public AuthData register(String account, String password, String nickname) {
        if (users.existsByAccount(account)) {
            throw new ApiException("账号已存在", HttpStatus.BAD_REQUEST);
        }
        String nick = (nickname == null || nickname.isBlank()) ? account : nickname;
        String hash = encoder.encode(password);
        User saved = users.save(new User(account, nick, null, hash));

        // 新建默认设置行
        settings.save(new Settings(saved.getId()));

        String token = jwt.generate(saved.getId(), saved.getAccount());
        return new AuthData(saved.getId(), saved.getAccount(), saved.getNickname(), token);
    }

    @Transactional(readOnly = true)
    public AuthData login(String account, String password) {
        User u = users.findByAccount(account)
                .orElseThrow(() -> new ApiException("账号或密码错误", HttpStatus.UNAUTHORIZED));
        if (!encoder.matches(password, u.getPasswordHash())) {
            throw new ApiException("账号或密码错误", HttpStatus.UNAUTHORIZED);
        }
        String token = jwt.generate(u.getId(), u.getAccount());
        return new AuthData(u.getId(), u.getAccount(), u.getNickname(), token);
    }
}
