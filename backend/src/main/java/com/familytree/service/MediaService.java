package com.familytree.service;

import com.familytree.entity.FamilyMemberEntity;
import com.familytree.repository.FamilyMemberRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.Base64;
import java.util.NoSuchElementException;

@Service
@RequiredArgsConstructor
public class MediaService {

    private final FamilyMemberRepository memberRepository;

    @Value("${app.photo.max-size-bytes}")
    private long maxSizeBytes;

    /**
     * Accepts a photo upload, validates size, converts to base64, and stores on the member entity.
     */
    public FamilyMemberEntity uploadPhoto(String memberId, MultipartFile file) throws IOException {
        if (file.getSize() > maxSizeBytes) {
            throw new IllegalArgumentException(
                    "Photo size exceeds maximum allowed size of " + (maxSizeBytes / 1024) + " KB. " +
                    "Uploaded file size: " + (file.getSize() / 1024) + " KB.");
        }

        FamilyMemberEntity member = memberRepository.findById(memberId)
                .orElseThrow(() -> new NoSuchElementException("Member not found: " + memberId));

        String mimeType = file.getContentType() != null ? file.getContentType() : "image/jpeg";
        String base64 = "data:" + mimeType + ";base64," + Base64.getEncoder().encodeToString(file.getBytes());

        member.setPhotoBase64(base64);
        memberRepository.save(member);

        return member;
    }

    /**
     * Returns the base64 photo string for a member, or null if none exists.
     */
    public String getPhoto(String memberId) {
        FamilyMemberEntity member = memberRepository.findById(memberId)
                .orElseThrow(() -> new NoSuchElementException("Member not found: " + memberId));
        return member.getPhotoBase64();
    }
}
