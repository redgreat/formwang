-- PostgreSQL 初始化脚本
-- 创建数据库（如果不存在）
SELECT 'CREATE DATABASE formwang_dev' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'formwang_dev')\gexec
SELECT 'CREATE DATABASE formwang_test' WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'formwang_test')\gexec

-- 注意：在Docker环境中，主数据库已通过环境变量创建
-- 用户也已通过环境变量创建并拥有相应权限