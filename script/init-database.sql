-- FormWang 数据库初始化脚本
-- 用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_admin BOOLEAN DEFAULT FALSE,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 表单表
CREATE TABLE IF NOT EXISTS forms (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    user_id INTEGER REFERENCES users(id),
    public_token VARCHAR(255) UNIQUE,
    private_token VARCHAR(255) UNIQUE,
    is_active BOOLEAN DEFAULT TRUE,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 字段表
CREATE TABLE IF NOT EXISTS form_fields (
    id SERIAL PRIMARY KEY,
    form_id INTEGER REFERENCES forms(id) ON DELETE CASCADE,
    field_type VARCHAR(50) NOT NULL,
    label VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    is_required BOOLEAN DEFAULT FALSE,
    options JSONB,
    position INTEGER DEFAULT 0,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 提交记录表
CREATE TABLE IF NOT EXISTS form_submissions (
    id SERIAL PRIMARY KEY,
    form_id INTEGER REFERENCES forms(id) ON DELETE CASCADE,
    data JSONB NOT NULL,
    ip_address INET,
    user_agent TEXT,
    inserted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_forms_user_id ON forms(user_id);
CREATE INDEX IF NOT EXISTS idx_forms_public_token ON forms(public_token);
CREATE INDEX IF NOT EXISTS idx_forms_private_token ON forms(private_token);
CREATE INDEX IF NOT EXISTS idx_form_fields_form_id ON form_fields(form_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_form_id ON form_submissions(form_id);
CREATE INDEX IF NOT EXISTS idx_form_submissions_inserted_at ON form_submissions(inserted_at);

-- 插入默认管理员用户（密码: admin123）
INSERT INTO users (email, password_hash, is_admin) 
VALUES ('admin@formwang.com', '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj/VjPyeC9/u', TRUE)
ON CONFLICT (email) DO NOTHING;

SELECT 'Database initialization completed successfully!' as result;