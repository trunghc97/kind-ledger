package com.kindledger.gateway.service;

import com.kindledger.gateway.model.User;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class UserService {
    
    private List<User> users;
    private DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    public UserService() {
        this.users = new ArrayList<>();
        initializeDefaultUsers();
    }

    private void initializeDefaultUsers() {
        User admin = new User();
        admin.setId("user-001");
        admin.setUsername("admin");
        admin.setEmail("admin@kindledger.com");
        admin.setPassword("$2a$10$dummy"); // In production, use BCrypt
        admin.setFullName("Administrator");
        admin.setRole("ADMIN");
        admin.setStatus("ACTIVE");
        admin.setCreatedAt(LocalDateTime.now().minusMonths(1).format(formatter));
        admin.setUpdatedAt(LocalDateTime.now().format(formatter));
        users.add(admin);

        User normalUser = new User();
        normalUser.setId("user-002");
        normalUser.setUsername("user");
        normalUser.setEmail("user@kindledger.com");
        normalUser.setPassword("$2a$10$dummy"); // In production, use BCrypt
        normalUser.setFullName("Normal User");
        normalUser.setRole("USER");
        normalUser.setStatus("ACTIVE");
        normalUser.setCreatedAt(LocalDateTime.now().minusWeeks(2).format(formatter));
        normalUser.setUpdatedAt(LocalDateTime.now().format(formatter));
        users.add(normalUser);
    }

    public User register(String username, String email, String password, String fullName) {
        // Check if username or email already exists
        if (findByUsername(username).isPresent()) {
            throw new RuntimeException("Username already exists");
        }
        if (findByEmail(email).isPresent()) {
            throw new RuntimeException("Email already exists");
        }

        // Create new user
        User user = new User();
        user.setId("user-" + UUID.randomUUID().toString());
        user.setUsername(username);
        user.setEmail(email);
        user.setPassword(password); // In production, hash this with BCrypt
        user.setFullName(fullName);
        user.setRole("USER");
        user.setStatus("ACTIVE");
        user.setCreatedAt(LocalDateTime.now().format(formatter));
        user.setUpdatedAt(LocalDateTime.now().format(formatter));
        
        users.add(user);
        return user;
    }

    public User login(String username, String password) {
        Optional<User> userOpt = findByUsername(username);
        
        if (userOpt.isEmpty()) {
            throw new RuntimeException("Invalid username or password");
        }

        User user = userOpt.get();
        
        // In production, use BCrypt to check password
        if (!user.getPassword().equals(password)) {
            throw new RuntimeException("Invalid username or password");
        }

        if (!"ACTIVE".equals(user.getStatus())) {
            throw new RuntimeException("Account is not active");
        }

        return user;
    }

    public Optional<User> findByUsername(String username) {
        return users.stream()
                .filter(u -> u.getUsername().equals(username))
                .findFirst();
    }

    public Optional<User> findByEmail(String email) {
        return users.stream()
                .filter(u -> u.getEmail().equals(email))
                .findFirst();
    }

    public Optional<User> findById(String id) {
        return users.stream()
                .filter(u -> u.getId().equals(id))
                .findFirst();
    }

    public List<User> getAllUsers() {
        return new ArrayList<>(users);
    }
}

