package com.cle2333.flightattendance.dto;

import jakarta.validation.constraints.NotNull;

import java.time.Instant;

public record CreateRecordRequest(@NotNull Instant time, String note) {
}
