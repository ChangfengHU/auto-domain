-- ==============================================================
-- 添加扩展字段到 tunnel_instances 表
-- 用于存储客户端 IP、OS 类型和其他元数据信息
-- ==============================================================

-- 添加客户端 IP 字段
ALTER TABLE public.tunnel_instances ADD COLUMN IF NOT EXISTS client_ip TEXT;

-- 添加操作系统类型字段 ('mac', 'linux', 'windows')
ALTER TABLE public.tunnel_instances ADD COLUMN IF NOT EXISTS os_type TEXT;

-- 添加元数据 JSON 字段用于存储其他信息
ALTER TABLE public.tunnel_instances ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 添加索引以加快客户端 IP 的查询
CREATE INDEX IF NOT EXISTS idx_tunnel_instances_client_ip ON public.tunnel_instances(client_ip);

-- 添加索引以加快操作系统类型的查询
CREATE INDEX IF NOT EXISTS idx_tunnel_instances_os_type ON public.tunnel_instances(os_type);

-- 添加自动更新 updated_at 字段的触发器（如果还没有的话）
-- 这个已经在 init.sql 中定义了，这里仅作备注
