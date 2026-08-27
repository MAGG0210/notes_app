-- ============================================
-- 云笔记 App: notes 表 + RLS 策略
-- 在 Supabase 控制台 → SQL Editor 里执行
-- ============================================

-- 1. 创建 notes 表
create table if not exists public.notes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null default '',
  content text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. 索引: 按用户查询加速
create index if not exists notes_user_idx on public.notes (user_id);
create index if not exists notes_updated_idx on public.notes (updated_at desc);

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
