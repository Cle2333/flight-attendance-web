package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public record RegisterRequest(
        @NotBlank @Size(min = 3, max = 20) String account,
        @NotBlank @Size(min = 6) String password,
        String nickname
) {
}
