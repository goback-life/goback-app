-- Migration: Add 'text' to content_type enum
-- Run this SQL in your Supabase SQL editor to add support for text posts

ALTER TYPE public.content_type ADD VALUE IF NOT EXISTS 'text';

