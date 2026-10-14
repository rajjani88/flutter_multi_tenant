import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accent
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color accent = Color(0xFFEC4899); // Pink

  // Neutral & Surfaces (Dark & Light modes)
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceHover = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);

  // Text
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFF94A3B8);
  static const Color textMutedDark = Color(0xFF64748B);

  // Status Colors
  static const Color statusToDo = Color(0xFFF59E0B); // Amber
  static const Color statusInProgress = Color(0xFF3B82F6); // Blue
  static const Color statusDone = Color(0xFF10B981); // Emerald

  // Priority Colors
  static const Color priorityLow = Color(0xFF64748B); // Slate
  static const Color priorityMedium = Color(0xFF3B82F6); // Blue
  static const Color priorityHigh = Color(0xFFF97316); // Orange
  static const Color priorityUrgent = Color(0xFFEF4444); // Red

  // Role Badges
  static const Color roleOwner = Color(0xFF8B5CF6); // Purple
  static const Color roleAdmin = Color(0xFF3B82F6); // Blue
  static const Color roleManager = Color(0xFF10B981); // Emerald
  static const Color roleMember = Color(0xFF06B6D4); // Cyan
  static const Color roleViewer = Color(0xFF64748B); // Slate

  // Status Alerts
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color info = Color(0xFF0284C7);
}
