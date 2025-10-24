package com.kindledger.gateway.repository;

import com.kindledger.gateway.entity.UserEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface UserRepository extends JpaRepository<UserEntity, UUID> {
    
    Optional<UserEntity> findByUsername(String username);
    
    Optional<UserEntity> findByEmail(String email);
    
    List<UserEntity> findByOrganization(String organization);
    
    List<UserEntity> findByRole(UserEntity.UserRole role);
    
    List<UserEntity> findByStatus(UserEntity.UserStatus status);
    
    List<UserEntity> findByOrganizationAndRole(String organization, UserEntity.UserRole role);
    
    @Query("SELECT u FROM UserEntity u WHERE u.username = :username OR u.email = :email")
    Optional<UserEntity> findByUsernameOrEmail(@Param("username") String username, @Param("email") String email);
    
    @Query("SELECT u FROM UserEntity u WHERE u.organization = :organization AND u.status = 'ACTIVE'")
    List<UserEntity> findActiveUsersByOrganization(@Param("organization") String organization);
    
    @Query("SELECT u FROM UserEntity u WHERE u.role = :role AND u.status = 'ACTIVE'")
    List<UserEntity> findActiveUsersByRole(@Param("role") UserEntity.UserRole role);
    
    @Query("SELECT COUNT(u) FROM UserEntity u WHERE u.organization = :organization")
    Long countByOrganization(@Param("organization") String organization);
    
    @Query("SELECT COUNT(u) FROM UserEntity u WHERE u.role = :role")
    Long countByRole(@Param("role") UserEntity.UserRole role);
    
    @Query("SELECT COUNT(u) FROM UserEntity u WHERE u.status = :status")
    Long countByStatus(@Param("status") UserEntity.UserStatus status);
    
    @Query("SELECT u FROM UserEntity u WHERE u.lastLogin BETWEEN :startDate AND :endDate")
    List<UserEntity> findUsersByLastLoginRange(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT u FROM UserEntity u WHERE u.lastLogin IS NULL")
    List<UserEntity> findUsersNeverLoggedIn();
    
    boolean existsByUsername(String username);
    
    boolean existsByEmail(String email);
}
