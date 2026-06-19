package com.cle2333.flightattendance.service;

import com.cle2333.flightattendance.dto.RecordDto;
import com.cle2333.flightattendance.dto.SyncRecordItem;
import com.cle2333.flightattendance.entity.Record;
import com.cle2333.flightattendance.exception.ApiException;
import com.cle2333.flightattendance.repository.RecordRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.List;
import java.util.Map;

@Service
public class RecordService {

    private final RecordRepository records;

    public RecordService(RecordRepository records) {
        this.records = records;
    }

    @Transactional(readOnly = true)
    public List<RecordDto> list(Long userId) {
        return records.findByUserIdOrderByTimeAsc(userId)
                .stream().map(RecordDto::from).toList();
    }

    @Transactional
    public Long add(Long userId, Instant time, String note) {
        Record saved = records.save(new Record(userId, time, note));
        return saved.getId();
    }

    @Transactional
    public void update(Long userId, Long id, Instant time, String note) {
        Record r = records.findById(id)
                .orElseThrow(() -> new ApiException("记录不存在", HttpStatus.NOT_FOUND));
        if (!r.getUserId().equals(userId)) {
            // 不是自己的记录也返回 404，避免 IDOR 探测
            throw new ApiException("记录不存在", HttpStatus.NOT_FOUND);
        }
        r.setTime(time);
        r.setNote(note);
        records.save(r);
    }

    @Transactional
    public void delete(Long userId, Long id) {
        Record r = records.findById(id)
                .orElseThrow(() -> new ApiException("记录不存在", HttpStatus.NOT_FOUND));
        if (!r.getUserId().equals(userId)) {
            throw new ApiException("记录不存在", HttpStatus.NOT_FOUND);
        }
        records.delete(r);
    }

    @Transactional
    public int sync(Long userId, List<SyncRecordItem> items) {
        if (items == null) {
            throw new ApiException("记录格式错误", HttpStatus.BAD_REQUEST);
        }
        // 替换式同步：删旧 + 批量插新
        records.deleteAllByUserId(userId);
        for (SyncRecordItem item : items) {
            records.save(new Record(userId, item.time(), item.note()));
        }
        return items.size();
    }
}
