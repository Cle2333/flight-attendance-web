package com.cle2333.flightattendance.security;

import java.io.Serializable;

public record UserPrincipal(Long userId, String account) implements Serializable {
}
