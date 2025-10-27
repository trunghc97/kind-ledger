package com.kindledger.gateway.controller;

import com.kindledger.gateway.model.AuthResponse;
import com.kindledger.gateway.model.LoginRequest;
import com.kindledger.gateway.model.RegisterRequest;
import com.kindledger.gateway.model.User;
import com.kindledger.gateway.service.UserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthenticationController {

    private static final Logger logger = LoggerFactory.getLogger(AuthenticationController.class);

    @Autowired
    private UserService userService;

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody RegisterRequest request) {
        try {
            logger.info("Registering new user: {}", request.getUsername());

            // Validate request
            if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
                return createErrorResponse("Username is required");
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                return createErrorResponse("Password is required");
            }
            if (request.getEmail() == null || request.getEmail().trim().isEmpty()) {
                return createErrorResponse("Email is required");
            }
            if (request.getFullName() == null || request.getFullName().trim().isEmpty()) {
                return createErrorResponse("Full name is required");
            }

            // Register user
            User user = userService.register(
                    request.getUsername(),
                    request.getEmail(),
                    request.getPassword(),
                    request.getFullName()
            );

            // Generate token (simple mock token)
            String token = "Bearer " + UUID.randomUUID().toString();

            // Create response
            AuthResponse authResponse = new AuthResponse();
            authResponse.setToken(token);
            authResponse.setUserId(user.getId());
            authResponse.setUsername(user.getUsername());
            authResponse.setEmail(user.getEmail());
            authResponse.setFullName(user.getFullName());
            authResponse.setRole(user.getRole());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "User registered successfully");
            response.put("data", authResponse);

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            logger.error("Error registering user: {}", e.getMessage());
            return createErrorResponse(e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error registering user: {}", e.getMessage());
            return createErrorResponse("Failed to register user");
        }
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody LoginRequest request) {
        try {
            logger.info("Login attempt for user: {}", request.getUsername());

            // Validate request
            if (request.getUsername() == null || request.getUsername().trim().isEmpty()) {
                return createErrorResponse("Username is required");
            }
            if (request.getPassword() == null || request.getPassword().trim().isEmpty()) {
                return createErrorResponse("Password is required");
            }

            // Authenticate user
            User user = userService.login(request.getUsername(), request.getPassword());

            // Generate token (simple mock token)
            String token = "Bearer " + UUID.randomUUID().toString();

            // Create response
            AuthResponse authResponse = new AuthResponse();
            authResponse.setToken(token);
            authResponse.setUserId(user.getId());
            authResponse.setUsername(user.getUsername());
            authResponse.setEmail(user.getEmail());
            authResponse.setFullName(user.getFullName());
            authResponse.setRole(user.getRole());

            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Login successful");
            response.put("data", authResponse);

            return ResponseEntity.ok(response);

        } catch (RuntimeException e) {
            logger.error("Error logging in user: {}", e.getMessage());
            return createErrorResponse(e.getMessage());
        } catch (Exception e) {
            logger.error("Unexpected error logging in user: {}", e.getMessage());
            return createErrorResponse("Failed to login");
        }
    }

    @GetMapping("/me")
    public ResponseEntity<Map<String, Object>> getCurrentUser(@RequestHeader(value = "Authorization", required = false) String token) {
        Map<String, Object> response = new HashMap<>();
        
        if (token == null || !token.startsWith("Bearer ")) {
            response.put("success", false);
            response.put("message", "Unauthorized");
            return ResponseEntity.status(401).body(response);
        }

        // In a real implementation, you would validate the token and extract user info
        // For now, return mock data
        Map<String, Object> userData = new HashMap<>();
        userData.put("id", "user-001");
        userData.put("username", "admin");
        userData.put("email", "admin@kindledger.com");
        userData.put("fullName", "Administrator");
        userData.put("role", "ADMIN");

        response.put("success", true);
        response.put("data", userData);

        return ResponseEntity.ok(response);
    }

    private ResponseEntity<Map<String, Object>> createErrorResponse(String message) {
        Map<String, Object> response = new HashMap<>();
        response.put("success", false);
        response.put("message", message);
        return ResponseEntity.badRequest().body(response);
    }
}

