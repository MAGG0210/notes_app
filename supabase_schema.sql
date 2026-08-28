-- ============================================
-- 云笔记 App: notes 表 + RLS 策略
-- 在 Supabase 控制台 → SQL Editor 里执行
-- ============================================

-- 1. 创建 notes 表
--    pinned: 是否置顶；tags: 笔记标签（字符串数组）
--    deleted_at: 回收站软删除标记（null=正常，非空=在回收站）
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  pinned boolean not null default false,
  tags text[] not null default '{}',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. 索引: 按用户查询加速 / 标签 GIN 索引 / 置顶排序 / 回收站筛选
create index if not exists notes_user_idx on public.notes (user_id);
create index if not exists notes_updated_idx on public.notes (updated_at desc);
create index if not exists notes_tags_idx on public.notes using gin (tags);
create index if not exists notes_deleted_idx on public.notes (user_id, deleted_at);

-- 3. 开启行级安全(RLS)
alter table public.notes enable row level security;

-- 4. RLS 策略: 用户只能读写自己的笔记
create policy "users_select_own_notes"
  on public.notes for select
  using (auth.uid() = user_id);

create policy "users_insert_own_notes"
  on public.notes for insert
  with check (auth.uid() = user_id);

create policy "users_update_own_notes"
  on public.notes for update
  using (auth.uid() = user_id);

create policy "users_delete_own_notes"
  on public.notes for delete
  using (auth.uid() = user_id);

-- 5. 开启 Realtime (多端实时同步的关键)
alter publication supabase_realtime add table public.notes;

-- 6. 触发 updated_at 自动更新
create or replace function public.handle_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

create trigger notes_updated_at
  before update on public.notes
  for each row execute function public.handle_updated_at();

-- ============================================
-- 增量迁移 SQL（v1.1 → v1.2）
-- 已在旧版本部署过的用户，仅需执行下面这段：
-- ============================================
-- alter table public.notes
--   add column if not exists pinned boolean not null default false,
--   add column if not exists tags text[] not null default '{}',
--   add column if not exists deleted_at timestamptz;
--
-- create index if not exists notes_tags_idx on public.notes using gin (tags);
-- create index if not exists notes_deleted_idx on public.notes (user_id, deleted_at);
