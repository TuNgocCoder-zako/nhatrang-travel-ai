-- =====================================================================
-- Flyway Migration V1: Initial Schema (11 Tables)
-- Project: Nha Trang AI Tourism Map (nhatrang-ai-tourism-map)
-- Database: MySQL 8 (InnoDB, utf8mb4_unicode_ci)
-- =====================================================================

-- 1. Người dùng & Phân quyền
CREATE TABLE users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    role ENUM('USER', 'ADMIN') NOT NULL DEFAULT 'USER',
    preferred_lang ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL DEFAULT 'vi',
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 2. Địa điểm du lịch (Tọa độ & Thông số lõi)
CREATE TABLE places (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    slug VARCHAR(150) NOT NULL UNIQUE,
    category ENUM('HERITAGE', 'MUSEUM', 'BEACH', 'ISLAND', 'WELLNESS', 'ENTERTAINMENT') NOT NULL,
    access_type ENUM('ROAD', 'ISLAND') NOT NULL DEFAULT 'ROAD',
    latitude DECIMAL(10, 7) NOT NULL,
    longitude DECIMAL(10, 7) NOT NULL,
    transfer_point_name VARCHAR(150) NULL,
    transfer_lat DECIMAL(10, 7) NULL,
    transfer_lng DECIMAL(10, 7) NULL,
    opening_hours VARCHAR(100) NULL,
    official_ticket_url VARCHAR(500) NULL,
    avg_rating DECIMAL(3, 2) NOT NULL DEFAULT 0.00,
    review_count INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_places_category (category),
    INDEX idx_places_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3. Nội dung thuyết minh đa ngôn ngữ (5 ngôn ngữ)
CREATE TABLE place_translations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    place_id BIGINT NOT NULL,
    lang_code ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL,
    name VARCHAR(200) NOT NULL,
    short_description VARCHAR(500) NOT NULL,
    history_content TEXT NOT NULL,
    visitor_tips TEXT NULL,
    transport_note VARCHAR(500) NULL,
    is_machine_translated BOOLEAN NOT NULL DEFAULT FALSE,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    UNIQUE KEY uk_place_lang (place_id, lang_code),
    CONSTRAINT fk_place_trans_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 4. Hình ảnh địa điểm (Cloudinary URLs)
CREATE TABLE place_images (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    place_id BIGINT NOT NULL,
    image_url VARCHAR(500) NOT NULL,
    caption VARCHAR(255) NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    sort_order INT NOT NULL DEFAULT 0,
    INDEX idx_place_images_place (place_id, sort_order),
    CONSTRAINT fk_place_img_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 5. Video review mạng xã hội theo ngôn ngữ (YouTube, TikTok, Facebook, Instagram...)
CREATE TABLE place_videos (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    place_id BIGINT NOT NULL,
    platform ENUM('YOUTUBE', 'TIKTOK', 'FACEBOOK', 'INSTAGRAM', 'OTHER') NOT NULL,
    lang_code ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL,
    title VARCHAR(200) NOT NULL,
    author_name VARCHAR(100) NULL,
    video_url VARCHAR(500) NOT NULL,
    thumbnail_url VARCHAR(500) NULL,
    sort_order INT NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    updated_by BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_place_videos_lang (place_id, lang_code, is_active, sort_order),
    CONSTRAINT fk_video_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT fk_video_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 6. Bảng giá vé cổng tham khảo (Có vết quản trị viên cập nhật)
CREATE TABLE ticket_prices (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    place_id BIGINT NOT NULL,
    ticket_type VARCHAR(100) NOT NULL,
    price_vnd INT NOT NULL DEFAULT 0,
    note VARCHAR(255) NULL,
    source_url VARCHAR(500) NULL,
    updated_by BIGINT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_ticket_place (place_id),
    CONSTRAINT fk_ticket_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 7. Biểu giá cước taxi địa phương (Có vết quản trị viên cập nhật)
CREATE TABLE taxi_fares (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    provider_name VARCHAR(100) NOT NULL,
    vehicle_type VARCHAR(50) NOT NULL,
    base_fare_vnd INT NOT NULL,
    base_distance_km DECIMAL(4, 2) NOT NULL,
    per_km_vnd INT NOT NULL,
    source_url VARCHAR(500) NULL,
    updated_by BIGINT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_taxi_updated_by FOREIGN KEY (updated_by) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 8. Đánh giá của du khách (Hỗ trợ lọc đa tiêu chí & xếp hạng theo lượt hữu ích)
CREATE TABLE reviews (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    place_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    rating TINYINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    original_lang ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL,
    original_content TEXT NOT NULL,
    helpful_count INT NOT NULL DEFAULT 0,
    status ENUM('PENDING', 'APPROVED', 'REJECTED') NOT NULL DEFAULT 'APPROVED',
    is_sample_data BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_reviews_filter (place_id, status, rating, helpful_count DESC, created_at DESC),
    INDEX idx_reviews_lang (place_id, status, original_lang),
    CONSTRAINT fk_review_place FOREIGN KEY (place_id) REFERENCES places(id) ON DELETE CASCADE,
    CONSTRAINT fk_review_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 9. Lượt bình chọn "Hữu ích" cho đánh giá (Mỗi user tối đa 1 lượt / 1 bài)
CREATE TABLE review_helpful_votes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_review_user_vote (review_id, user_id),
    CONSTRAINT fk_vote_review FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE,
    CONSTRAINT fk_vote_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 10. Lưu đệm (Cache) bản dịch đánh giá (Tùy chọn - có thể bỏ nếu không dùng nút dịch lẻ)
CREATE TABLE review_translations (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    review_id BIGINT NOT NULL,
    target_lang ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL,
    translated_content TEXT NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uk_review_target_lang (review_id, target_lang),
    CONSTRAINT fk_rev_trans_review FOREIGN KEY (review_id) REFERENCES reviews(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 11. Nhật ký hỏi đáp Trợ lý AI 24/7, Rate Limit & Đo hiệu năng model
CREATE TABLE ai_chat_logs (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NULL,
    session_id VARCHAR(100) NOT NULL,
    user_lang ENUM('vi', 'en', 'ko', 'ru', 'zh') NOT NULL,
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    highlighted_place_ids JSON NULL,
    model_used VARCHAR(50) NOT NULL,
    input_tokens INT NOT NULL DEFAULT 0,
    output_tokens INT NOT NULL DEFAULT 0,
    latency_ms INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_chat_user_time (user_id, created_at),
    INDEX idx_chat_session (session_id, created_at),
    INDEX idx_chat_model_time (model_used, created_at),
    CONSTRAINT fk_chat_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;