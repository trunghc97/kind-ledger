package com.kindledger.gateway.service;

import com.kindledger.gateway.entity.UserEntity;
import com.kindledger.gateway.entity.WalletEntity;
import com.kindledger.gateway.model.User;
import com.kindledger.gateway.repository.UserRepository;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;
import java.util.UUID;

@Service
@RequiredArgsConstructor
@Transactional
public class UserService {

    private final UserRepository userRepository;
    private final WalletService walletService;

    private final DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss");

    public User register(String username, String email, String password, String fullName) {
        if (userRepository.existsByUsername(username)) {
            throw new RuntimeException("Username already exists");
        }
        if (userRepository.existsByEmail(email)) {
            throw new RuntimeException("Email already exists");
        }

        UserEntity entity = new UserEntity();
        entity.setUsername(username);
        entity.setEmail(email);
        entity.setPasswordHash(password); // TODO: hash with BCrypt in production
        entity.setFullName(fullName);
        entity.setRole(UserEntity.UserRole.USER);
        entity.setStatus(UserEntity.UserStatus.ACTIVE);
        entity.setCreatedAt(LocalDateTime.now());
        entity.setUpdatedAt(LocalDateTime.now());
        // Ensure metadata is null so PostgreSQL jsonb accepts NULL instead of VARCHAR
        entity.setMetadata(null);

        UserEntity saved = userRepository.save(entity);

        // Create a wallet for the new user and link it.
        // The UserEntity is still managed by the persistence context,
        // so changes will be flushed at the end of the transaction.
        WalletEntity wallet = walletService.createPendingWalletForUser(saved.getId(), "klw-" + UUID.randomUUID());
        saved.setWalletId(wallet.getId());

        User user = new User();
        user.setId("user-" + saved.getId().toString());
        user.setUsername(saved.getUsername());
        user.setEmail(saved.getEmail());
        user.setFullName(saved.getFullName());
        user.setRole(saved.getRole().name());
        user.setStatus(saved.getStatus().name());
        user.setCreatedAt(saved.getCreatedAt().format(formatter));
        user.setUpdatedAt(saved.getUpdatedAt().format(formatter));
        return user;
    }

    public User login(String username, String password) {
        Optional<UserEntity> userOpt = userRepository.findByUsername(username);
        if (userOpt.isEmpty()) {
            throw new RuntimeException("Invalid username or password");
        }
        UserEntity entity = userOpt.get();
        if (!entity.getPasswordHash().equals(password)) {
            throw new RuntimeException("Invalid username or password");
        }
        if (!UserEntity.UserStatus.ACTIVE.equals(entity.getStatus())) {
            throw new RuntimeException("Account is not active");
        }
        entity.setLastLogin(LocalDateTime.now());
        userRepository.save(entity);

        User user = new User();
        user.setId("user-" + entity.getId().toString());
        user.setUsername(entity.getUsername());
        user.setEmail(entity.getEmail());
        user.setFullName(entity.getFullName());
        user.setRole(entity.getRole().name());
        user.setStatus(entity.getStatus().name());
        user.setCreatedAt(entity.getCreatedAt() != null ? entity.getCreatedAt().format(formatter) : null);
        user.setUpdatedAt(entity.getUpdatedAt() != null ? entity.getUpdatedAt().format(formatter) : null);
        return user;
    }
}
