-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Feb 08, 2026 at 10:18 AM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `smartspot`
--

-- --------------------------------------------------------

--
-- Table structure for table `parking_spots`
--

CREATE TABLE `parking_spots` (
  `id` int(11) NOT NULL,
  `spot_number` int(11) DEFAULT NULL,
  `isAvailable` tinyint(1) DEFAULT NULL,
  `mall_id` int(11) NOT NULL DEFAULT 1
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `parking_spots`
--

INSERT INTO `parking_spots` (`id`, `spot_number`, `isAvailable`, `mall_id`) VALUES
(1, 1, 0, 1),
(2, 2, 1, 1),
(3, 3, 1, 1),
(4, 4, 0, 1),
(5, 5, 1, 1),
(6, 6, 0, 1),
(7, 7, 1, 1),
(8, 8, 0, 1),
(9, 9, 1, 1),
(10, 10, 1, 1),
(11, 11, 1, 1),
(12, 12, 1, 1),
(13, 13, 1, 1),
(14, 14, 0, 1),
(15, 15, 1, 1),
(16, 16, 1, 1),
(17, 17, 1, 1),
(18, 18, 1, 1),
(19, 19, 1, 1),
(20, 20, 0, 1),
(21, 1, 1, 2),
(22, 2, 1, 2),
(23, 3, 0, 2),
(24, 4, 0, 2),
(25, 5, 0, 2),
(26, 6, 0, 2),
(27, 7, 1, 2),
(28, 8, 0, 2),
(29, 9, 1, 2),
(30, 10, 0, 2),
(31, 11, 1, 2),
(32, 12, 0, 2),
(33, 13, 0, 2),
(34, 14, 1, 2),
(35, 15, 1, 2),
(36, 16, 1, 2),
(37, 17, 1, 2),
(38, 18, 1, 2),
(39, 19, 0, 2),
(40, 20, 1, 2),
(41, 21, 1, 2),
(42, 22, 0, 2),
(43, 23, 1, 2),
(44, 24, 1, 2),
(45, 25, 1, 2),
(46, 26, 0, 2),
(47, 27, 0, 2),
(48, 28, 0, 2),
(49, 29, 0, 2),
(50, 30, 1, 2),
(51, 31, 0, 2),
(52, 32, 0, 2),
(53, 33, 1, 2),
(54, 34, 1, 2),
(55, 35, 1, 2),
(56, 36, 0, 2),
(57, 37, 0, 2),
(58, 38, 1, 2),
(59, 39, 0, 2),
(60, 40, 1, 2);

-- --------------------------------------------------------

--
-- Table structure for table `reservations`
--

CREATE TABLE `reservations` (
  `id` int(11) NOT NULL,
  `user_id` int(11) DEFAULT NULL,
  `spot_id` int(11) DEFAULT NULL,
  `status` varchar(20) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `mall_id` int(11) NOT NULL DEFAULT 1,
  `start_time` datetime DEFAULT NULL,
  `paid_hours` int(11) DEFAULT NULL,
  `end_time` datetime DEFAULT NULL,
  `penalty_paid` tinyint(1) DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `reservations`
--

INSERT INTO `reservations` (`id`, `user_id`, `spot_id`, `status`, `created_at`, `mall_id`, `start_time`, `paid_hours`, `end_time`, `penalty_paid`) VALUES
(11, 2, 8, 'completed', '2025-12-10 10:10:13', 1, NULL, 1, '1970-01-01 08:30:00', 1),
(12, 2, 12, 'completed', '2025-12-10 10:10:15', 1, NULL, NULL, NULL, 0),
(13, 2, 10, 'completed', '2025-12-10 10:20:11', 1, NULL, NULL, NULL, 0),
(86, 4, 12, 'cancelled', '2026-01-22 15:30:10', 1, NULL, NULL, NULL, 0),
(87, 4, 12, 'completed', '2026-01-22 15:30:33', 1, '2026-01-22 23:30:40', 1, '2026-01-23 00:30:40', 0),
(88, 4, 12, 'completed', '2026-01-22 15:31:05', 1, '2026-01-22 23:31:11', 1, '2026-01-23 00:31:11', 1),
(107, 2, 13, 'completed', '2026-01-24 09:33:26', 1, '2026-01-24 17:33:38', 2, '2026-01-24 17:39:23', 1),
(108, 4, 8, 'occupied', '2026-01-28 01:39:40', 1, '2026-01-28 09:40:57', 1, '2026-01-28 09:51:41', 0),
(109, 2, 13, 'completed', '2026-01-31 07:30:10', 1, '2026-01-31 15:30:26', 1, '2026-01-31 15:32:12', 1),
(110, 2, 16, 'completed', '2026-01-31 07:34:35', 1, '2026-01-31 15:35:11', 1, '2026-01-31 15:47:50', 1),
(111, 2, 39, 'reserved', '2026-01-31 07:36:22', 2, NULL, NULL, NULL, 0),
(112, 5, 18, 'completed', '2026-01-31 07:43:09', 1, '2026-01-31 15:43:28', 2, '2026-01-31 17:43:28', 0),
(113, 5, 18, 'completed', '2026-01-31 07:44:44', 1, '2026-01-31 15:44:59', 2, '2026-01-31 16:53:06', 0),
(114, 5, 18, 'completed', '2026-01-31 07:46:59', 1, '2026-01-31 15:47:22', 1, '2026-01-31 15:46:28', 1),
(115, 2, 17, 'completed', '2026-02-01 10:31:57', 1, '2026-02-01 18:32:20', 1, '2026-02-01 19:32:20', 0),
(116, 2, 17, 'cancelled', '2026-02-01 10:32:51', 1, NULL, NULL, NULL, 0),
(117, 2, 17, 'completed', '2026-02-01 10:33:29', 1, '2026-02-01 18:33:37', 1, '2026-02-01 18:28:32', 1),
(118, 2, 17, 'completed', '2026-02-03 13:21:13', 1, '2026-02-03 21:21:28', 1, '2026-02-03 22:21:28', 0),
(119, 2, 17, 'completed', '2026-02-03 13:37:01', 1, '2026-02-03 21:37:43', 1, '2026-02-03 22:37:43', 0);

-- --------------------------------------------------------

--
-- Table structure for table `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(100) NOT NULL,
  `password_hash` varchar(255) NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `role` enum('user','admin') DEFAULT 'user'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `users`
--

INSERT INTO `users` (`id`, `name`, `email`, `password_hash`, `created_at`, `role`) VALUES
(1, 'Drew', 'wwh0617@gmail.com', '$2b$10$OwQR2HaP8F4jNOy.4oZ3AuBv275T584TQ61Gr6iOXrUy3pzlReA5O', '2025-11-29 07:33:49', 'user'),
(2, 'hello', '123@gmail.com', '$2b$10$TQpzCq9dSpaJ3EhM7wEa2..O7JUrEiM6TXs5n0gavxCbZFqmahyrG', '2025-11-29 07:35:52', 'user'),
(3, 'admin', 'admin@gmail.com', '$2b$10$x680wqmFrijkdJ84j802c.xxS.soVeeu3NgzkzRpZEZfHCGsv9uAm', '2026-01-05 08:38:38', 'admin'),
(4, 'pass', '12@gmail.com', '$2b$10$KHU6sRDnIYRUguI4/jl3Kew/omZ.BTXPPgd6Wh1vq9C.mlnm6A8XS', '2026-01-22 10:34:43', 'user'),
(5, 'Test1', 'test1@gmail.com', '$2b$10$cKCFM1K07pwks4BBNw.Lcucud3qwhxEhghk9VUMO0D03Gwcs1ok0C', '2026-01-31 07:42:40', 'user');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `parking_spots`
--
ALTER TABLE `parking_spots`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `reservations`
--
ALTER TABLE `reservations`
  ADD PRIMARY KEY (`id`);

--
-- Indexes for table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`),
  ADD UNIQUE KEY `email` (`email`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `parking_spots`
--
ALTER TABLE `parking_spots`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=61;

--
-- AUTO_INCREMENT for table `reservations`
--
ALTER TABLE `reservations`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=120;

--
-- AUTO_INCREMENT for table `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
