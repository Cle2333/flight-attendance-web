package com.cle2333.flightattendance.dto;

import java.time.Instant;

public record SyncRecordItem(Instant time, String note) {
}
