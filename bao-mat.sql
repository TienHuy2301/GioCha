-- =====================================================================
-- GIÒ CHẢ - BỔ SUNG BẢO MẬT & PHÂN QUYỀN (chạy MỘT LẦN, chạy lại nhiều lần cũng an toàn)
-- Chạy SAU khi đã chạy supabase.sql. Không làm mất dữ liệu.
-- =====================================================================

-- 1. Nhân viên KHÔNG đọc được nhà cung cấp và phiếu nhập (giá vốn nhập hàng).
--    Quản trị viên đọc được tất cả. Nhân viên chỉ đọc: sản phẩm, đơn hàng, khách hàng, cài đặt.
drop policy if exists rec_sel on public.records;
create policy rec_sel on public.records for select to authenticated
  using (
    shop_id = public.my_shop()
    and (public.my_role() = 'admin' or store in ('products','orders','customers','settings'))
  );

-- 2. Chỉ quản trị viên được XÓA dữ liệu (đơn hàng, khách hàng, sản phẩm...).
--    Nhân viên vẫn thêm và sửa được đơn hàng, khách hàng như cũ.
drop policy if exists rec_del on public.records;
create policy rec_del on public.records for delete to authenticated
  using (shop_id = public.my_shop() and public.my_role() = 'admin');

-- 3. Nhân viên chỉ xem được hồ sơ của chính mình (không thấy email đồng nghiệp).
--    Quản trị viên xem được danh sách thành viên trong cơ sở.
drop policy if exists prof_sel on public.profiles;
create policy prof_sel on public.profiles for select to authenticated
  using (id = auth.uid() or (shop_id = public.my_shop() and public.my_role() = 'admin'));

-- 4. Người chưa đăng nhập (anon) không có bất kỳ quyền nào với dữ liệu.
revoke all on public.records, public.profiles, public.shops from anon;
revoke truncate, references, trigger on public.records, public.profiles, public.shops from authenticated;

-- 5. Chỉ chấp nhận đúng các loại dữ liệu của ứng dụng (chặn ghi dữ liệu lạ).
do $$ begin
  alter table public.records add constraint records_store_ck
    check (store in ('products','orders','customers','suppliers','imports','settings'));
exception when duplicate_object then null; end $$;

-- 6. Ghi dấu người sửa và thời điểm sửa gần nhất (để truy vết khi cần).
create or replace function public.records_touch() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  new.updated_at := now();
  new.updated_by := auth.uid();
  return new;
end $$;
drop trigger if exists records_touch on public.records;
create trigger records_touch before insert or update on public.records
  for each row execute function public.records_touch();

-- 7. Mã mời dài hơn (12 ký tự) để khó đoán. Mã cũ vẫn dùng được cho đến khi bấm "Đổi mã".
alter table public.shops alter column invite_code
  set default substr(replace(gen_random_uuid()::text,'-',''),1,12);
create or replace function public.regen_invite() returns text
language plpgsql security definer set search_path = public as $$
declare v text;
begin
  if coalesce(public.my_role(),'') <> 'admin' then raise exception 'Chỉ quản trị viên được đổi mã'; end if;
  update public.shops set invite_code = substr(replace(gen_random_uuid()::text,'-',''),1,12)
    where id = public.my_shop() returning invite_code into v;
  return v;
end $$;
revoke all on function public.regen_invite() from public, anon;
grant execute on function public.regen_invite() to authenticated;

-- 8. Kho ảnh: chỉ nhận ảnh JPG/PNG/WEBP, tối đa 1 MB mỗi ảnh.
update storage.buckets
   set file_size_limit = 1048576,
       allowed_mime_types = array['image/jpeg','image/png','image/webp']
 where id = 'product-images';
