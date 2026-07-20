package com.familytree.controller;

import com.familytree.entity.FamilyMemberEntity;
import com.familytree.service.MediaService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.Map;

@RestController
@RequiredArgsConstructor
public class MediaController {

    private final MediaService mediaService;

    @PostMapping("/api/members/{memberId}/photo")
    public ResponseEntity<?> uploadPhoto(
            @PathVariable String memberId,
            @RequestParam("file") MultipartFile file) {
        try {
            FamilyMemberEntity member = mediaService.uploadPhoto(memberId, file);
            return ResponseEntity.ok(Map.of(
                    "memberId", member.getId(),
                    "message", "Photo uploaded successfully"
            ));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of("error", e.getMessage()));
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "Failed to process photo"));
        }
    }

    @GetMapping("/api/media/{memberId}")
    public ResponseEntity<?> getPhoto(@PathVariable String memberId) {
        String base64 = mediaService.getPhoto(memberId);
        if (base64 == null || base64.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        // If it's a data URI, extract the bytes and stream them
        if (base64.startsWith("data:")) {
            try {
                String[] parts = base64.split(",", 2);
                String meta = parts[0]; // e.g. data:image/jpeg;base64
                String mimeType = meta.substring(5, meta.indexOf(";"));
                byte[] bytes = Base64.getDecoder().decode(parts[1]);
                return ResponseEntity.ok()
                        .contentType(MediaType.parseMediaType(mimeType))
                        .body(bytes);
            } catch (Exception e) {
                return ResponseEntity.ok(Map.of("photo", base64));
            }
        }
        return ResponseEntity.ok(Map.of("photo", base64));
    }
}
