-- =====================================================================
-- GIÒ CHẢ - Cơ sở dữ liệu Supabase (chạy MỘT LẦN trong SQL Editor)
-- =====================================================================

-- 1. Bảng
create table if not exists public.shops (
  id uuid primary key default gen_random_uuid(),
  name text not null default 'Cơ sở giò chả',
  invite_code text not null default substr(replace(gen_random_uuid()::text,'-',''),1,8),
  created_at timestamptz default now()
);
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  shop_id uuid references public.shops(id) on delete set null,
  role text not null default 'staff' check (role in ('admin','staff')),
  created_at timestamptz default now()
);
create table if not exists public.records (
  shop_id uuid not null references public.shops(id) on delete cascade,
  store text not null,            -- products | orders | customers | suppliers | imports | settings
  id text not null,
  data jsonb not null,
  updated_at timestamptz default now(),
  updated_by uuid default auth.uid(),
  primary key (shop_id, store, id)
);
create index if not exists records_shop_store on public.records(shop_id, store);

-- 2. Tự tạo hồ sơ khi có người đăng ký
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles(id, email) values (new.id, new.email) on conflict do nothing;
  return new;
end $$;
drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();
insert into public.profiles(id, email) select id, email from auth.users on conflict do nothing;

-- 3. Hàm hỗ trợ phân quyền
create or replace function public.my_shop() returns uuid
language sql stable security definer set search_path = public as
$$ select shop_id from public.profiles where id = auth.uid() $$;
create or replace function public.my_role() returns text
language sql stable security definer set search_path = public as
$$ select role from public.profiles where id = auth.uid() $$;
-- Quản trị viên ghi được mọi thứ; nhân viên chỉ ghi đơn hàng và khách hàng
create or replace function public.can_write(p_store text) returns boolean
language sql stable security definer set search_path = public as
$$ select coalesce(public.my_role(),'') = 'admin' or p_store in ('orders','customers') $$;

-- 4. Row Level Security
alter table public.shops enable row level security;
alter table public.profiles enable row level security;
alter table public.records enable row level security;

drop policy if exists shops_sel on public.shops;
create policy shops_sel on public.shops for select to authenticated using (id = public.my_shop());
drop policy if exists shops_upd on public.shops;
create policy shops_upd on public.shops for update to authenticated
  using (id = public.my_shop() and public.my_role() = 'admin') with check (id = public.my_shop());

drop policy if exists prof_sel on public.profiles;
create policy prof_sel on public.profiles for select to authenticated
  using (id = auth.uid() or shop_id = public.my_shop());
-- Không có policy insert/update/delete cho profiles: chỉ đổi qua các hàm bên dưới

drop policy if exists rec_sel on public.records;
create policy rec_sel on public.records for select to authenticated using (shop_id = public.my_shop());
drop policy if exists rec_ins on public.records;
create policy rec_ins on public.records for insert to authenticated
  with check (shop_id = public.my_shop() and public.can_write(store));
drop policy if exists rec_upd on public.records;
create policy rec_upd on public.records for update to authenticated
  using (shop_id = public.my_shop() and public.can_write(store))
  with check (shop_id = public.my_shop() and public.can_write(store));
drop policy if exists rec_del on public.records;
create policy rec_del on public.records for delete to authenticated
  using (shop_id = public.my_shop() and public.can_write(store));

-- 5. Các hàm quản lý cơ sở và nhân viên
create or replace function public.create_shop(p_name text) returns uuid
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  insert into public.profiles(id, email) select id, email from auth.users where id = auth.uid() on conflict do nothing;
  if exists (select 1 from public.profiles where id = auth.uid() and shop_id is not null) then
    raise exception 'Tài khoản đã thuộc một cơ sở';
  end if;
  insert into public.shops(name) values (coalesce(nullif(trim(p_name),''),'Cơ sở giò chả')) returning id into v;
  update public.profiles set shop_id = v, role = 'admin' where id = auth.uid();
  return v;
end $$;

create or replace function public.join_shop(p_code text) returns void
language plpgsql security definer set search_path = public as $$
declare v uuid;
begin
  select id into v from public.shops where invite_code = lower(trim(p_code));
  if v is null then raise exception 'Mã mời không đúng'; end if;
  update public.profiles set shop_id = v, role = 'staff' where id = auth.uid() and shop_id is null;
end $$;

create or replace function public.set_member_role(p_user uuid, p_role text) returns void
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(public.my_role(),'') <> 'admin' then raise exception 'Chỉ quản trị viên được đổi quyền'; end if;
  if p_role not in ('admin','staff') then raise exception 'Quyền không hợp lệ'; end if;
  if p_user = auth.uid() then raise exception 'Không thể tự đổi quyền của mình'; end if;
  update public.profiles set role = p_role where id = p_user and shop_id = public.my_shop();
end $$;

create or replace function public.remove_member(p_user uuid) returns void
language plpgsql security definer set search_path = public as $$
begin
  if coalesce(public.my_role(),'') <> 'admin' then raise exception 'Chỉ quản trị viên được xóa nhân viên'; end if;
  if p_user = auth.uid() then raise exception 'Không thể tự xóa mình'; end if;
  update public.profiles set shop_id = null, role = 'staff' where id = p_user and shop_id = public.my_shop();
end $$;

create or replace function public.regen_invite() returns text
language plpgsql security definer set search_path = public as $$
declare v text;
begin
  if coalesce(public.my_role(),'') <> 'admin' then raise exception 'Chỉ quản trị viên được đổi mã'; end if;
  update public.shops set invite_code = substr(replace(gen_random_uuid()::text,'-',''),1,8)
    where id = public.my_shop() returning invite_code into v;
  return v;
end $$;

-- 6. Quyền thực thi: chỉ người đã đăng nhập
revoke all on function public.my_shop(), public.my_role(), public.can_write(text),
  public.create_shop(text), public.join_shop(text), public.set_member_role(uuid,text),
  public.remove_member(uuid), public.regen_invite() from public, anon;
grant execute on function public.my_shop(), public.my_role(), public.can_write(text),
  public.create_shop(text), public.join_shop(text), public.set_member_role(uuid,text),
  public.remove_member(uuid), public.regen_invite() to authenticated;

-- 7. Ảnh sản phẩm (kho lưu trữ công khai để đọc, chỉ quản trị viên được tải lên)
insert into storage.buckets (id, name, public) values ('product-images','product-images', true)
  on conflict (id) do nothing;
drop policy if exists img_ins on storage.objects;
create policy img_ins on storage.objects for insert to authenticated
  with check (bucket_id = 'product-images' and (storage.foldername(name))[1] = public.my_shop()::text and public.my_role() = 'admin');
drop policy if exists img_del on storage.objects;
create policy img_del on storage.objects for delete to authenticated
  using (bucket_id = 'product-images' and (storage.foldername(name))[1] = public.my_shop()::text and public.my_role() = 'admin');

-- 8. Đồng bộ thời gian thực giữa các thiết bị
do $$ begin
  alter publication supabase_realtime add table public.records;
exception when duplicate_object then null; end $$;
