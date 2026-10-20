# HƯỚNG DẪN CÀI ĐẶT APP GIÒ CHẢ (Supabase + cài như app trên điện thoại)

Làm lần lượt từng bước. Tổng thời gian khoảng 30 phút. Tất cả đều có gói miễn phí.

Bộ tệp gồm: `index.html` (app), `config.js` (nơi điền khóa Supabase), `supabase.sql` (tạo cơ sở dữ liệu), `manifest.json`, `sw.js`, `icon-192.png`, `icon-512.png` (để cài như app).

---
## BƯỚC 1. Tạo dự án Supabase
1. Vào https://supabase.com, bấm **Start your project**, đăng ký bằng email hoặc GitHub.
2. Bấm **New project**. Điền:
   - **Name**: gio-cha
   - **Database Password**: bấm *Generate* rồi **lưu lại** ở nơi an toàn
   - **Region**: *Southeast Asia (Singapore)* cho nhanh
3. Bấm **Create new project**, chờ 1 đến 2 phút.

## BƯỚC 2. Tạo bảng dữ liệu và phân quyền
1. Menu trái chọn **SQL Editor**, bấm **New query**.
2. Mở tệp `supabase.sql` bằng Notepad (hoặc ứng dụng ghi chú), chọn tất cả, sao chép.
3. Dán vào ô SQL Editor, bấm **Run** (hoặc Ctrl+Enter).
4. Thấy dòng "Success. No rows returned" là xong. Nếu báo lỗi đỏ, chụp màn hình gửi lại cho mình.

## BƯỚC 3. Lấy 2 khóa kết nối
1. Menu trái chọn **Project Settings** (biểu tượng bánh răng) rồi **API** (hoặc **API Keys**).
2. Sao chép **Project URL** (dạng `https://xxxx.supabase.co`).
3. Sao chép khóa **anon public** (chuỗi dài bắt đầu bằng `eyJ...`).
4. Mở tệp `config.js`, dán vào giữa 2 dấu nháy:
```
window.CFG={
  url:'https://xxxx.supabase.co',
  key:'eyJ...'
};
```
5. Lưu tệp. **Không bao giờ** dùng khóa `service_role` ở đây. Khóa anon là công khai và an toàn vì dữ liệu được bảo vệ bằng RLS đã tạo ở Bước 2.

## BƯỚC 4. Đưa app lên mạng (để dùng được trên điện thoại)
App cần một địa chỉ `https://` thì mới cài được như app thật. Cách dễ nhất là Netlify:
1. Giải nén tệp zip, bạn sẽ có thư mục `gio-cha-app` (đã sửa `config.js`).
2. Vào https://app.netlify.com/drop (đăng ký tài khoản miễn phí nếu được hỏi).
3. **Kéo cả thư mục `gio-cha-app`** thả vào khung trên trang.
4. Chờ vài giây, Netlify cho bạn một địa chỉ dạng `https://ten-ngau-nhien.netlify.app`. Vào **Site configuration > Change site name** để đổi thành tên dễ nhớ, ví dụ `giocha-ten-ban.netlify.app`.
5. Ghi lại địa chỉ này.

Khi muốn cập nhật bản mới: vào site trên Netlify, mục **Deploys**, kéo thư mục mới thả vào.

## BƯỚC 5. Báo cho Supabase biết địa chỉ app
1. Trong Supabase: **Authentication** > **URL Configuration**.
2. **Site URL**: dán địa chỉ Netlify (ví dụ `https://giocha-ten-ban.netlify.app`).
3. **Redirect URLs**: bấm *Add URL*, dán cùng địa chỉ đó, Save.
Bước này để email xác nhận và email đặt lại mật khẩu dẫn về đúng app.

## BƯỚC 6. Cài đặt gửi email
- Supabase mặc định gửi rất ít email mỗi giờ (khoảng vài email), có thể gây lỗi khi nhiều người đăng ký.
- **Cách đơn giản cho cơ sở nhỏ**: vào **Authentication** > **Sign In / Providers** > **Email**, tắt **Confirm email**. Khi đó đăng ký xong dùng được ngay, không cần xác nhận qua email. Chức năng quên mật khẩu vẫn gửi email nên cần có mạng email bình thường.
- **Cách chuyên nghiệp hơn**: cấu hình SMTP riêng (**Authentication > SMTP Settings**) với Gmail, Resend, v.v.

## BƯỚC 7. Tạo tài khoản chủ cơ sở (quản trị viên)
1. Mở địa chỉ app trên điện thoại hoặc máy tính.
2. Bấm **Tạo tài khoản mới**, nhập email và mật khẩu từ 8 ký tự, bấm **Đăng ký**.
3. Nếu đã tắt xác nhận email ở Bước 6 thì vào luôn. Nếu chưa, mở email, bấm liên kết xác nhận, quay lại đăng nhập.
4. Ở màn hình **Chọn cơ sở**, nhập tên cơ sở rồi bấm **Tạo cơ sở mới**. Tài khoản này là **quản trị viên**.

## BƯỚC 8. Thêm nhân viên
1. Quản trị viên vào **Cài đặt** (nút dưới cùng), kéo xuống mục **Nhân viên**, thấy **Mã mời** (8 ký tự).
2. Gửi mã này cho nhân viên.
3. Nhân viên mở app, **Tạo tài khoản mới**, sau đó ở màn hình **Chọn cơ sở** nhập mã vào ô "Mã mời" rồi bấm **Tham gia cơ sở**.
4. Quyền của từng người:
   - **Quản trị viên**: mọi chức năng (sản phẩm, nhập nguyên liệu, nhà cung cấp, cài đặt, tài khoản, sao lưu).
   - **Nhân viên**: bán hàng, khách hàng, lịch sử, thống kê.
   - Quản trị viên có thể đổi quyền, xóa nhân viên, hoặc bấm **Đổi mã** để vô hiệu mã mời cũ.
   - Phân quyền được chặn ngay trong cơ sở dữ liệu, không chỉ ẩn nút.

## BƯỚC 9. Cài lên màn hình chính điện thoại như app thật
**iPhone (bắt buộc dùng Safari):**
1. Mở địa chỉ app bằng Safari, đăng nhập.
2. Bấm nút Chia sẻ (ô vuông có mũi tên lên).
3. Chọn **Thêm vào Màn hình chính** > **Thêm**.

**Android (Chrome):**
1. Mở địa chỉ app bằng Chrome, đăng nhập.
2. Bấm dấu 3 chấm > **Cài đặt ứng dụng** (hoặc **Thêm vào màn hình chính**).

Sau đó mở bằng biểu tượng xanh lá ngoài màn hình, app chạy toàn màn hình, không có thanh trình duyệt.

## BƯỚC 10. Chuyển dữ liệu cũ từ bản thử (nếu có)
1. Mở bản cũ (link claude.ai trước đây), vào **Cài đặt** > **Sao lưu toàn bộ dữ liệu**, bấm **Sao chép**.
2. Mở app mới bằng tài khoản quản trị viên, vào **Cài đặt** > **Khôi phục từ bản sao lưu**, dán vào và xác nhận.
Lưu ý: khôi phục sẽ **ghi đè** dữ liệu hiện có, chỉ làm khi app mới còn trống.

## Sao lưu định kỳ
- Trong app: **Cài đặt** > **Xuất lịch sử bán hàng (CSV)** hoặc **Sao lưu toàn bộ dữ liệu** (có nút **Tải tệp**). Nên làm mỗi tuần.
- Trong Supabase: **Database > Backups** (gói miễn phí chỉ có xuất thủ công, gói Pro mới có sao lưu hằng ngày).
- Gói miễn phí của Supabase sẽ **tạm dừng dự án nếu 7 ngày không có hoạt động**. Dùng hằng ngày thì không sao; nếu bị dừng, vào dashboard bấm *Restore*.

## Khi gặp sự cố
| Hiện tượng | Cách xử lý |
|---|---|
| Màn hình "Chưa cấu hình" | `config.js` chưa điền URL và key, hoặc quên tải lại thư mục lên Netlify |
| "Sai email hoặc mật khẩu" | Kiểm tra lại, hoặc dùng **Quên mật khẩu** |
| Đăng ký xong không vào được | Chưa bấm liên kết xác nhận trong email (hoặc tắt Confirm email ở Bước 6) |
| Email không đến | Xem thư mục Spam; hoặc cấu hình SMTP riêng (Bước 6) |
| "Không có quyền ghi" | Tài khoản nhân viên đang làm thao tác chỉ dành cho quản trị viên |
| Dữ liệu không đồng bộ | Kiểm tra mạng; góc trên bên phải phải hiện "Đã đồng bộ ✓" |
| Sau khi cập nhật vẫn thấy bản cũ | Đóng hẳn app, mở lại 2 lần (app lưu bản tải sẵn để mở nhanh) |
| Gặp lỗi khác | Chụp màn hình và gửi lại cho mình |

## Lưu ý bảo mật
- Chỉ dùng khóa **anon** trong `config.js`.
- Không gửi mật khẩu Supabase hay khóa `service_role` cho ai.
- Nhân viên nghỉ việc: quản trị viên bấm **Xóa** ở mục Nhân viên, rồi **Đổi mã** mời.


---

## Bảo mật và phân quyền (làm một lần)

1. Vào Supabase → **SQL Editor** → **New query**.
2. Mở tệp `bao-mat.sql`, sao chép toàn bộ nội dung, dán vào ô lệnh, bấm **Run**. Kết quả đúng là "Success. No rows returned". Chạy lại nhiều lần cũng an toàn, dữ liệu không mất.
   (Nếu cài mới từ đầu thì `supabase.sql` đã gồm sẵn phần này.)
3. Sau khi chạy:
   - Nhân viên không đọc được nhà cung cấp và phiếu nhập (giá vốn).
   - Chỉ quản trị viên được xóa đơn hàng, khách hàng, sản phẩm.
   - Nhân viên chỉ thấy hồ sơ của chính mình.
   - Người chưa đăng nhập không đọc được gì.
   - Mã mời mới dài 12 ký tự (vào mục Tài khoản bấm "Đổi mã" để lấy mã mới).
4. Nên bật thêm trong Supabase → **Authentication**:
   - **Sign In / Providers → Email**: mật khẩu tối thiểu 8 ký tự, bật "Prevent use of leaked passwords" nếu có.
   - Khi nhân viên đã đăng ký đủ, có thể tắt **Allow new users to sign up** (Authentication → Sign In / Providers) để người lạ không tạo thêm tài khoản. Cần thêm nhân viên mới thì bật lại.
