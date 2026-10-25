-- =====================================================================
-- GIÒ CHẢ - NHẬT KÝ THAO TÁC (chạy MỘT LẦN trong Supabase → SQL Editor)
-- Chạy SAU supabase.sql và bao-mat.sql. Chạy lại nhiều lần vẫn an toàn.
--
-- Ghi lại: ai, lúc nào, thêm / sửa / xóa cái gì (đơn hàng, khách hàng, sản phẩm,
-- nhà cung cấp, phiếu nhập). Chỉ QUẢN TRỊ VIÊN xem được (Tài khoản → Nhật ký thao tác).
-- Bản chi tiết: ghi rõ TRƯỜNG NÀO đổi từ gì sang gì (giá, số lượng, khách, ghi chú...), danh sách
-- hàng trong đơn, và các sự kiện hệ thống (sao lưu, xuất Excel, xóa toàn bộ dữ liệu).
-- Nhẹ: mỗi dòng vài trăm byte, tự xóa dòng cũ hơn 90 ngày. Không tốn phí.
-- =====================================================================

create table if not exists public.audit_log (
  id bigint generated always as identity primary key,
  shop_id uuid not null,
  at timestamptz not null default now(),
  uid uuid,
  email text,
  action text not null,      -- Thêm | Sửa | Xóa
  store text not null,       -- orders | customers | products | suppliers | imports
  rec_id text,
  summary text
);
alter table public.audit_log add column if not exists detail jsonb;  -- [[nhãn, cũ, mới], ...]
create index if not exists audit_log_shop_at on public.audit_log (shop_id, at desc);

alter table public.audit_log enable row level security;
drop policy if exists audit_sel on public.audit_log;
create policy audit_sel on public.audit_log for select to authenticated
  using (shop_id = public.my_shop() and public.my_role() = 'admin');
-- Không ai (kể cả quản trị viên) sửa/xóa được nhật ký từ ứng dụng: chỉ trigger ghi vào.
revoke all on public.audit_log from anon, authenticated;
grant select on public.audit_log to authenticated;

-- Định dạng một giá trị để hiển thị
create or replace function public.audit_fmt(k text, v jsonb) returns text
language plpgsql immutable as $$
begin
  if k = 'status' and (v is null or v = 'null'::jsonb or (v #>> '{}') <> 'cancelled') then return 'Hợp lệ'; end if;
  if v is null or v = 'null'::jsonb or (v #>> '{}') = '' then return '(trống)'; end if;
  if k in ('price','wprice','cost','amt','discount','dep') then
    return replace(to_char(round((v #>> '{}')::numeric),'FM999G999G999G999'),',','.');
  elsif k = 'active' then return case when v = 'true'::jsonb then 'Đang kinh doanh' else 'Ngừng kinh doanh' end;
  elsif k = 'status' then return case when (v #>> '{}') = 'cancelled' then 'Đã hủy' else 'Hợp lệ' end;
  elsif k = 'pm' then return case v #>> '{}' when 'bank' then 'Chuyển khoản' when 'debt' then 'Ghi nợ' else 'Tiền mặt' end;
  elsif k = 'type' then return case when (v #>> '{}') = 'si' then 'Bán sỉ' else 'Bán lẻ' end;
  elsif k = 'kind' then return case v #>> '{}' when 'pay' then 'Trả nợ NCC' when 'loss' then 'Chênh lệch kiểm kê' else 'Nhập hàng' end;
  end if;
  return left(v #>> '{}', 100);
exception when others then
  return left(coalesce(v #>> '{}',''), 100);
end $$;

-- Một dòng hàng trong đơn: "2 kg × 120.000"
create or replace function public.audit_line(it jsonb) returns text
language sql immutable as $$
  select coalesce(it->>'qty','0') || ' ' || coalesce(it->>'unit','') || ' × '
    || replace(to_char(round(coalesce((it->>'price')::numeric,0)),'FM999G999G999G999'),',','.') $$;

-- So sánh hai bản ghi, trả về mảng [[nhãn, cũ, mới], ...] (tối đa 16 mục)
create or replace function public.audit_detail(st text, o jsonb, n jsonb) returns jsonb
language plpgsql immutable as $$
declare
  lk text[]; ll text[]; ix int;
  res jsonb := '[]'::jsonb;
  k text; l text;
  src jsonb := coalesce(n, o);
  oi jsonb; ni jsonb; it jsonb; ox jsonb; ikey text; cnt int := 0;
begin
  if st = 'products' then
    lk := array['name','code','unit','price','wprice','cost','active','note'];
    ll := array['Tên','Mã','ĐVT','Giá bán','Giá sỉ','Giá vốn','Trạng thái','Ghi chú'];
  elsif st = 'customers' then
    lk := array['name','phone','addr','type','note'];
    ll := array['Tên','Điện thoại','Địa chỉ','Loại khách','Ghi chú'];
  elsif st = 'suppliers' then
    lk := array['name','phone','contact','addr','note'];
    ll := array['Tên','Điện thoại','Người liên hệ','Địa chỉ','Ghi chú'];
  elsif st = 'imports' then
    lk := array['kind','name','sname','qty','unit','price','amt','date','note'];
    ll := array['Loại','Nội dung','Nhà cung cấp','Số lượng','ĐVT','Đơn giá','Số tiền','Ngày','Ghi chú'];
  elsif st = 'orders' then
    lk := array['status','cname','type','pm','discount','dep','note'];
    ll := array['Trạng thái','Khách','Loại đơn','Thanh toán','Chiết khấu','Trả trước','Ghi chú'];
  else
    lk := array[]::text[]; ll := array[]::text[];
  end if;
  for ix in 1 .. coalesce(array_length(lk, 1), 0) loop
    k := lk[ix]; l := ll[ix];
    if o is null then
      if n ? k and (n->>k) is not null and (n->>k) <> '' and not (k in ('discount','dep','price','wprice','cost','amt') and (n->>k) = '0') then
        res := res || jsonb_build_array(jsonb_build_array(l, null, public.audit_fmt(k, n->k)));
      end if;
    elsif n is null then
      if o ? k and (o->>k) is not null and (o->>k) <> '' and not (k in ('discount','dep','price','wprice','cost','amt') and (o->>k) = '0') then
        res := res || jsonb_build_array(jsonb_build_array(l, public.audit_fmt(k, o->k), null));
      end if;
    elsif (o->k) is distinct from (n->k) and not (k = 'status' and public.audit_fmt(k, o->k) = public.audit_fmt(k, n->k)) then
      res := res || jsonb_build_array(jsonb_build_array(l, public.audit_fmt(k, o->k), public.audit_fmt(k, n->k)));
    end if;
  end loop;

  if st = 'orders' then
    oi := coalesce(o->'items','[]'::jsonb);
    ni := coalesce(n->'items','[]'::jsonb);
    if o is null then
      for it in select * from jsonb_array_elements(ni) loop
        exit when cnt >= 10; cnt := cnt + 1;
        res := res || jsonb_build_array(jsonb_build_array(coalesce(it->>'name','Hàng'), null, public.audit_line(it)));
      end loop;
    elsif n is null then
      for it in select * from jsonb_array_elements(oi) loop
        exit when cnt >= 10; cnt := cnt + 1;
        res := res || jsonb_build_array(jsonb_build_array(coalesce(it->>'name','Hàng'), public.audit_line(it), null));
      end loop;
    else
      for it in select * from jsonb_array_elements(ni) loop
        ikey := coalesce(it->>'pid', it->>'name');
        ox := (select e from jsonb_array_elements(oi) e where coalesce(e->>'pid', e->>'name') = ikey limit 1);
        if ox is null then
          res := res || jsonb_build_array(jsonb_build_array(coalesce(it->>'name','Hàng'), '(chưa có)', public.audit_line(it)));
        elsif (ox->>'qty') is distinct from (it->>'qty') or (ox->>'price') is distinct from (it->>'price') then
          res := res || jsonb_build_array(jsonb_build_array(coalesce(it->>'name','Hàng'), public.audit_line(ox), public.audit_line(it)));
        end if;
      end loop;
      for it in select * from jsonb_array_elements(oi) loop
        ikey := coalesce(it->>'pid', it->>'name');
        if not exists (select 1 from jsonb_array_elements(ni) e where coalesce(e->>'pid', e->>'name') = ikey) then
          res := res || jsonb_build_array(jsonb_build_array(coalesce(it->>'name','Hàng'), public.audit_line(it), '(đã bỏ)'));
        end if;
      end loop;
    end if;
  end if;

  -- giữ tối đa 16 mục
  return (select coalesce(jsonb_agg(x), '[]'::jsonb) from (select x from jsonb_array_elements(res) with ordinality t(x, ord) order by ord limit 16) q);
exception when others then
  return null;
end $$;

create or replace function public.audit_rec() returns trigger
language plpgsql security definer set search_path = public as $$
declare
  r public.records;
  act text;
  s text;
  em text;
  amt numeric;
  dt jsonb;
begin
  if coalesce(current_setting('app.skip_audit', true), '') = '1' then return null; end if;
  begin
    if tg_op = 'DELETE' then r := old; act := 'Xóa';
    elsif tg_op = 'INSERT' then r := new; act := 'Thêm';
    else
      if new.data is not distinct from old.data then return null; end if;
      r := new; act := 'Sửa';
    end if;
    if r.store = 'settings' then return null; end if;

    if r.store = 'orders' then
      select coalesce(sum(round(coalesce((i->>'qty')::numeric,0) * coalesce((i->>'price')::numeric,0))),0)
        into amt from jsonb_array_elements(coalesce(r.data->'items','[]'::jsonb)) i;
      amt := amt - coalesce((r.data->>'discount')::numeric,0);
      s := coalesce(r.data->>'code','') || ' · ' || replace(to_char(amt,'FM999G999G999G999'),',','.')
           || case when r.data->>'status' = 'cancelled' then ' · đã hủy' else '' end
           || case when coalesce(r.data->>'cname','') <> '' then ' · ' || (r.data->>'cname') else '' end;
    elsif r.store = 'imports' then
      amt := coalesce((r.data->>'qty')::numeric,0) * coalesce((r.data->>'price')::numeric,0);
      if r.data->>'kind' = 'pay' then amt := coalesce((r.data->>'amt')::numeric,0); end if;
      s := coalesce(nullif(r.data->>'kind',''),'in') || ' · ' || coalesce(r.data->>'name','')
           || case when amt > 0 then ' · ' || replace(to_char(round(amt),'FM999G999G999G999'),',','.') else '' end;
    else
      s := coalesce(r.data->>'name','');
    end if;
  exception when others then
    s := null;
  end;

  begin
    if tg_op = 'DELETE' then dt := public.audit_detail(r.store, old.data, null);
    elsif tg_op = 'INSERT' then dt := public.audit_detail(r.store, null, new.data);
    else dt := public.audit_detail(r.store, old.data, new.data); end if;
    if dt = '[]'::jsonb then dt := null; end if;
  exception when others then
    dt := null;
  end;

  if r.shop_id is null then return null; end if;
  select email into em from public.profiles where id = auth.uid();
  insert into public.audit_log(shop_id, uid, email, action, store, rec_id, summary, detail)
    values (r.shop_id, auth.uid(), em, act, r.store, r.id, left(s, 200), dt);
  if random() < 0.02 then
    delete from public.audit_log where at < now() - interval '90 days';
  end if;
  return null;
exception when others then
  return null;   -- nhật ký lỗi thì thôi, không bao giờ chặn việc lưu dữ liệu
end $$;
revoke all on function public.audit_rec() from public, anon, authenticated;

drop trigger if exists zz_audit on public.records;
create trigger zz_audit after insert or update or delete on public.records
  for each row execute function public.audit_rec();

revoke all on function public.audit_fmt(text, jsonb) from public, anon, authenticated;
revoke all on function public.audit_line(jsonb) from public, anon, authenticated;
revoke all on function public.audit_detail(text, jsonb, jsonb) from public, anon, authenticated;

-- Ghi sự kiện hệ thống từ ứng dụng (sao lưu, xuất Excel, khôi phục...). Không sửa/xóa được nhật ký cũ.
create or replace function public.log_event(p_action text, p_summary text) returns void
language plpgsql security definer set search_path = public as $$
declare em text;
begin
  if auth.uid() is null or public.my_shop() is null then return; end if;
  select email into em from public.profiles where id = auth.uid();
  insert into public.audit_log(shop_id, uid, email, action, store, summary)
    values (public.my_shop(), auth.uid(), em, left(coalesce(p_action,'Sự kiện'), 30), 'app', left(coalesce(p_summary,''), 200));
end $$;
revoke all on function public.log_event(text, text) from public, anon;
grant execute on function public.log_event(text, text) to authenticated;

-- Xóa toàn bộ dữ liệu kinh doanh của cửa hàng bằng 1 lệnh (chỉ quản trị viên), chỉ ghi 1 dòng nhật ký
create or replace function public.wipe_shop() returns integer
language plpgsql security definer set search_path = public as $$
declare n integer; em text;
begin
  if public.my_role() is distinct from 'admin' or public.my_shop() is null then
    raise exception 'not allowed' using errcode = '42501';
  end if;
  perform set_config('app.skip_audit', '1', true);
  delete from public.records
    where shop_id = public.my_shop()
      and store in ('products','orders','customers','suppliers','imports');
  get diagnostics n = row_count;
  select email into em from public.profiles where id = auth.uid();
  insert into public.audit_log(shop_id, uid, email, action, store, summary)
    values (public.my_shop(), auth.uid(), em, 'Xóa toàn bộ', 'app', 'Đã xóa ' || n || ' bản ghi dữ liệu');
  return n;
end $$;
revoke all on function public.wipe_shop() from public, anon;
grant execute on function public.wipe_shop() to authenticated;
