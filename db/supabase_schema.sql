-- Create posts table
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  title TEXT,
  content TEXT NOT NULL,
  images TEXT[] NOT NULL DEFAULT '{}',
  video_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create spotify_tokens table
CREATE TABLE IF NOT EXISTS spotify_tokens (
  id INT PRIMARY KEY,
  access_token TEXT NOT NULL,
  refresh_token TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL
);

-- Create analytics table
CREATE TABLE IF NOT EXISTS analytics (
  key TEXT PRIMARY KEY,
  value BIGINT DEFAULT 0
);
INSERT INTO analytics (key, value) VALUES ('total_views', 0) ON CONFLICT DO NOTHING;

-- Enable RLS
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE spotify_tokens ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics ENABLE ROW LEVEL SECURITY;

-- Policies for analytics
-- Allow everyone to read views
CREATE POLICY "Allow public read access" ON analytics
  FOR SELECT USING (true);

-- Policies for posts
-- Allow everyone to read posts
CREATE POLICY "Allow public read access" ON posts
  FOR SELECT USING (true);

-- Restrict write access to authenticated users (or service role)
-- Since we use a FastAPI backend with the direct connection string (postgres user),
-- it bypasses RLS anyway. These policies are for safety if client-side access is ever used.
CREATE POLICY "Restrict write to service role" ON posts
  FOR ALL TO service_role USING (true);

-- Policies for spotify_tokens
-- Completely private (only service role/postgres user)
CREATE POLICY "Restrict all to service role" ON spotify_tokens
  FOR ALL TO service_role USING (true);
