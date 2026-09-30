-- Set engine default dan charset ke UTF8MB4 (support full unicode & emoji)
SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- --------------------------------------------------------
-- 1. Table: roles
-- Memisahkan role ke tabel tersendiri mencegah privilege escalation via manipulasi input
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `roles` (
    `id` TINYINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(30) NOT NULL UNIQUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `roles` (`id`, `name`) VALUES
(1, 'admin'),
(2, 'member')
ON DUPLICATE KEY UPDATE `name`=`name`;

-- --------------------------------------------------------
-- 2. Table: users
-- Menyimpan kredensial autentikasi utama
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `role_id` TINYINT UNSIGNED NOT NULL DEFAULT 2,
    `email` VARCHAR(191) NOT NULL UNIQUE,
    `password` VARCHAR(255) NOT NULL, -- Cukup panjang untuk bcrypt / argon2id
    `is_active` TINYINT(1) NOT NULL DEFAULT 1,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_users_role` FOREIGN KEY (`role_id`) 
        REFERENCES `roles` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 3. Table: user_profiles
-- Memisahkan data profil sensitif/personal dari tabel kredensial auth
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `user_profiles` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL UNIQUE,
    `full_name` VARCHAR(100) NOT NULL,
    `bio` TEXT NULL,
    `phone_number` VARCHAR(20) NULL,
    `avatar` VARCHAR(255) NULL, -- Menyimpan nama hash file unik, bukan path mentah
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_profiles_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 4. Table: password_resets
-- Menyimpan hash token reset password (bukan plaintext token)
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `password_resets` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `email` VARCHAR(191) NOT NULL,
    `token_hash` CHAR(64) NOT NULL, -- SHA-256 hash dari random token
    `expires_at` DATETIME NOT NULL,
    `is_used` TINYINT(1) NOT NULL DEFAULT 0,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX `idx_pwd_reset_lookup` (`email`, `token_hash`, `is_used`, `expires_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 5. Table: categories
-- Klasifikasi/kategori buku
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `categories` (
    `id` SMALLINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(60) NOT NULL UNIQUE,
    `slug` VARCHAR(80) NOT NULL UNIQUE,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 6. Table: authors
-- Penulis buku dipisah agar satu penulis bisa punya banyak buku
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `authors` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `name` VARCHAR(100) NOT NULL,
    `bio` TEXT NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 7. Table: books
-- Katalog koleksi buku
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `books` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `category_id` SMALLINT UNSIGNED NOT NULL,
    `author_id` INT UNSIGNED NOT NULL,
    `isbn` VARCHAR(20) NULL UNIQUE,
    `title` VARCHAR(200) NOT NULL,
    `description` TEXT NULL,
    `stock` SMALLINT UNSIGNED NOT NULL DEFAULT 0,
    `cover_image` VARCHAR(255) NULL,
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_books_category` FOREIGN KEY (`category_id`) 
        REFERENCES `categories` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_books_author` FOREIGN KEY (`author_id`) 
        REFERENCES `authors` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX `idx_books_search` (`title`, `category_id`, `author_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- --------------------------------------------------------
-- 8. Table: borrowings
-- Transaksi peminjaman buku beserta siklus statusnya
-- --------------------------------------------------------
CREATE TABLE IF NOT EXISTS `borrowings` (
    `id` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    `user_id` INT UNSIGNED NOT NULL,
    `book_id` INT UNSIGNED NOT NULL,
    `borrow_date` DATE NOT NULL,
    `due_date` DATE NOT NULL,
    `return_date` DATE NULL,
    `status` ENUM('pending', 'approved', 'rejected', 'returned', 'overdue') NOT NULL DEFAULT 'pending',
    `fine_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    `notes` VARCHAR(255) NULL,
    `approved_by` INT UNSIGNED NULL, -- Admin / pustakawan yang melakukan approval
    `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    `updated_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `fk_loans_user` FOREIGN KEY (`user_id`) 
        REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT `fk_loans_book` FOREIGN KEY (`book_id`) 
        REFERENCES `books` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT `fk_loans_approver` FOREIGN KEY (`approved_by`) 
        REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX `idx_borrow_status` (`status`, `user_id`, `book_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;