package com.familytree.controller;

import com.familytree.entity.UserEntity;
import com.familytree.repository.UserRepository;
import com.familytree.security.JwtService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final UserRepository userRepository;
    private final JwtService jwtService;

    /**
     * Mock login endpoint. In production, this would verify a Google ID token.
     * For now, it accepts an email and role, creates/finds the user, and returns a JWT.
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "owner@example.com");
        String name = body.getOrDefault("name", "Mock User");
        String role = body.getOrDefault("role", "owner");

        UserEntity user = userRepository.findByEmail(email).orElseGet(() -> {
            UserEntity newUser = UserEntity.builder()
                    .id(UUID.randomUUID().toString())
                    .email(email)
                    .name(name)
                    .build();
            return userRepository.save(newUser);
        });

        String jwt = jwtService.generateToken(user.getId(), user.getEmail());

        return ResponseEntity.ok(Map.of(
                "jwt", jwt,
                "user", Map.of(
                        "id", user.getId(),
                        "email", user.getEmail(),
                        "name", user.getName(),
                        "avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : ""
                )
        ));
    }

    @PostMapping("/google")
    @SuppressWarnings("unchecked")
    public ResponseEntity<?> googleLogin(@RequestBody Map<String, String> body) {
        String idToken = body.get("idToken");
        String email = body.get("email");
        String name = body.getOrDefault("name", "Google User");
        String avatarUrl = body.get("avatarUrl");
        String googleId = body.get("googleId");

        if (idToken != null && !idToken.isBlank()) {
            try {
                org.springframework.web.client.RestTemplate restTemplate = new org.springframework.web.client.RestTemplate();
                String url = "https://oauth2.googleapis.com/tokeninfo?id_token=" + idToken;
                Map<String, Object> tokenInfo = restTemplate.getForObject(url, Map.class);
                if (tokenInfo != null && tokenInfo.containsKey("email")) {
                    email = (String) tokenInfo.get("email");
                    name = (String) tokenInfo.getOrDefault("name", name);
                    avatarUrl = (String) tokenInfo.getOrDefault("picture", avatarUrl);
                    googleId = (String) tokenInfo.get("sub");
                }
            } catch (Exception e) {
                System.err.println("Google ID token verification notice: " + e.getMessage());
            }
        }

        if (email == null || email.isBlank()) {
            return ResponseEntity.badRequest().body(Map.of("error", "Email is required"));
        }

        final String userEmail = email;
        final String userName = name;
        final String userAvatar = avatarUrl;
        final String userGoogleId = googleId;

        UserEntity user = userRepository.findByEmail(userEmail).map(u -> {
            if (userGoogleId != null) u.setGoogleId(userGoogleId);
            if (userAvatar != null) u.setAvatarUrl(userAvatar);
            return userRepository.save(u);
        }).orElseGet(() -> {
            UserEntity newUser = UserEntity.builder()
                    .id(UUID.randomUUID().toString())
                    .email(userEmail)
                    .name(userName)
                    .avatarUrl(userAvatar)
                    .googleId(userGoogleId)
                    .build();
            return userRepository.save(newUser);
        });

        String jwt = jwtService.generateToken(user.getId(), user.getEmail());

        return ResponseEntity.ok(Map.of(
                "jwt", jwt,
                "user", Map.of(
                        "id", user.getId(),
                        "email", user.getEmail(),
                        "name", user.getName(),
                        "avatarUrl", user.getAvatarUrl() != null ? user.getAvatarUrl() : ""
                )
        ));
    }
}
