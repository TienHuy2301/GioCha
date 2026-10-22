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
- Trong app: **Cài đặt** > **Xuất danh sách đơn hàng (CSV)** hoặc **Sao lưu toàn bộ dữ liệu** (có nút **Tải tệp**). Nên làm mỗi tuần.
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


---

## Bản v18: những tính năng mới và cách dùng

### Cập nhật lên v18 (đã cài app rồi)
Tải lên GitHub (ghi đè) các tệp: `index.html`, `sw.js`, `manifest.json` và 5 tệp ảnh `icon-192.png`, `icon-512.png`, `icon-maskable-512.png`, `apple-touch-icon.png`, `favicon-32.png`. **Không cần chạy lại SQL.** Mở app, đóng hẳn rồi mở lại 2 lần để nhận bản mới. Nếu icon trên màn hình chính còn cũ: xóa icon, mở lại trang web rồi thêm vào màn hình chính lần nữa.

### Cài mã QR thanh toán (VietQR) — làm một lần
1. Vào **Cài đặt > Thanh toán và in hóa đơn** (tài khoản quản trị viên).
2. Chọn **Ngân hàng**, nhập **Số tài khoản** và **Tên chủ tài khoản** (viết hoa, không dấu cho đúng với ngân hàng).
3. Bấm **Xem thử mã QR**, mở app ngân hàng trên điện thoại khác, quét thử. Phải thấy đúng ngân hàng, số tài khoản, tên chủ tài khoản.
4. Từ đó, mỗi đơn chọn **Chuyển khoản** sẽ tự hiện mã QR có sẵn **số tiền của đơn** và **nội dung là mã đơn** (ví dụ `DH261021004`, bỏ dấu gạch vì ngân hàng không nhận ký tự đặc biệt).

Nếu có vấn đề:
| Hiện tượng | Cách xử lý |
|---|---|
| App ngân hàng báo "mã QR không hợp lệ" | Kiểm tra lại số tài khoản và chọn đúng ngân hàng (sai ngân hàng là lỗi hay gặp nhất) |
| Quét ra sai tên chủ tài khoản | Số tài khoản sai hoặc chọn nhầm ngân hàng |
| Quét xong không thấy số tiền | Một vài app ngân hàng nhỏ bỏ qua số tiền; khách nhập tay theo số tiền trên màn hình |
| Nội dung chuyển khoản bị cắt hoặc bị đổi | Ngân hàng tự giới hạn độ dài nội dung; mã đơn đã được rút gọn tối đa |
| Muốn kiểm tra tiền đã về chưa | App **không** tự biết tiền đã vào tài khoản (cần dịch vụ đối soát riêng của ngân hàng). Xem tin nhắn biến động số dư rồi mới bấm hoàn tất đơn |
| QR không hiện | Chưa nhập ngân hàng/số tài khoản trong Cài đặt |

### Giá vốn, tồn kho và lợi nhuận (theo kế toán Việt Nam)
- Giá nguyên liệu tồn kho tính theo **bình quân gia quyền tức thời**: mỗi lần nhập kho, đơn giá bình quân được tính lại; xuất dùng và hao hụt được tính theo giá bình quân tại thời điểm đó.
- Hai cách tính **giá vốn hàng bán** (chọn ở **Cài đặt > Giá vốn và lợi nhuận**):
  1. **Theo giá vốn từng sản phẩm** (mặc định, dễ dùng): nhập "Giá vốn" cho mỗi sản phẩm, đơn nào bán ra thì giá vốn được chốt ngay lúc bán, nên đổi giá vốn sau này không làm sai đơn cũ.
  2. **Theo nguyên liệu xuất dùng**: giá vốn = giá trị nguyên liệu đã ghi "Xuất dùng" trong kỳ.
- Công thức:
  - Doanh thu thuần = Doanh thu bán hàng − Hàng trả lại − Chiết khấu
  - Lợi nhuận gộp = Doanh thu thuần − Giá vốn hàng bán
  - Lợi nhuận ròng = Lợi nhuận gộp − Chi phí vận hành − Nguyên vật liệu hao hụt
- Trong **Nhập nguyên liệu** có 4 loại phiếu: Nhập kho, Xuất dùng, Hao hụt, Chi phí (điện, nước, mặt bằng, lương...).
- Nhân viên không thấy giá vốn, lợi nhuận, tồn kho.

### Trang tổng quan và Thống kê
- Trang tổng quan có 6 ô chỉ số (2 hàng x 3 cột) và 3 nút tắt. Vào **Cài đặt > Trang tổng quan** để chọn ô hiển thị (tối đa 6).
- **Thống kê** xem theo Ngày / Tuần / Tháng / Năm / Tùy chọn, có so sánh với kỳ trước.

### Xuất Excel
Trong **Thống kê** bấm **Xuất báo cáo Excel**. Tệp có tiêu đề "BÁO CÁO DOANH THU & LỢI NHUẬN", dòng "Từ ngày … đến ngày …", nhiều trang tính (tổng hợp, theo ngày, chi tiết, sản phẩm, nhập kho, chi phí, tồn kho). Các ô tiền có định dạng VNĐ và dùng công thức, nên **sửa số liệu trực tiếp trong Excel thì tổng tự tính lại**. Tài khoản nhân viên chỉ xuất được phần doanh thu.

### In hóa đơn, gửi Zalo/SMS
- Sau khi lưu đơn có 4 nút: **In hóa đơn**, **Gửi Zalo / SMS**, **Mã QR thanh toán**, **Xem / Sửa đơn**.
- **In hóa đơn**: khổ giấy 58mm hoặc 80mm (chọn trong hộp thoại in).
  - Máy in nhiệt Bluetooth: dùng **Chrome trên Android** (bấm "In qua Bluetooth (máy in nhiệt)", chọn máy in một lần). iPhone/Safari không hỗ trợ Bluetooth trong trình duyệt.
  - iPhone: dùng nút in thường (AirPrint) hoặc máy in nhiệt có hỗ trợ AirPrint. Máy tính: máy in nhiệt cài driver bình thường rồi chọn khổ giấy.
  - Mỗi dòng máy in nhiệt khác nhau; nếu in lệch chữ hoặc mất dấu tiếng Việt, báo mình tên máy in để chỉnh.
- **Gửi Zalo / SMS**: SMS mở sẵn tin nhắn có nội dung hóa đơn; Zalo mở trò chuyện với số điện thoại khách và đã sao chép sẵn nội dung, chỉ cần dán và gửi (Zalo không cho app web gửi tự động).

### Nhiều máy cùng dùng một lúc
- Mỗi đơn, khách hàng, sản phẩm là một bản ghi riêng; hai máy sửa hai bản ghi khác nhau thì không ảnh hưởng nhau. Hai máy sửa **cùng một** bản ghi cùng lúc thì app báo xung đột, không im lặng ghi đè.
- Máy mất mạng vẫn bán hàng bình thường và tự đẩy lên khi có mạng lại.
- **Mã đơn trùng** (hai máy cùng tạo đơn lúc mất mạng): sau khi đồng bộ, đơn tạo sau tự được đánh lại mã (thêm chữ b, c...), tất cả máy cho cùng một kết quả.
- Lưu ý: app dùng cơ chế phát hiện xung đột theo từng bản ghi thay vì khóa cơ sở dữ liệu, phù hợp cho cửa hàng nhỏ với vài máy.


---

## Bản v19: Tổng quan, Đơn hàng, Cài đặt

**Cập nhật:** tải lên GitHub (ghi đè) `index.html`, `sw.js` (và `manifest.json` cùng 5 tệp icon nếu bạn chưa tải ở bản v18). Không cần chạy lại SQL, dữ liệu cũ giữ nguyên. Đóng hẳn app rồi mở lại 2 lần để nhận bản mới.

- **Tổng quan:** bấm biểu tượng bánh răng góc phải để chọn **ô chỉ số** (tối đa 6) và **lối tắt hình tròn** (tối đa 8, có Tạo đơn, Đơn hàng, Sản phẩm, Khách hàng, Thống kê, Tìm kiếm, Nguyên liệu, Xuất dùng, Hao hụt, Chi phí, Nhà cung cấp, Excel tháng này, Thanh toán QR, Cài đặt). Lối tắt hiện theo thứ tự bạn bấm chọn. Nhân viên chỉ thấy các lối tắt được phép. Lựa chọn lưu riêng trên từng thiết bị.
- **Đơn hàng** (trước đây là Lịch sử bán hàng): mở từ Cài đặt > Quản lý > Đơn hàng hoặc lối tắt. Xem theo Ngày, Tuần, Tháng hoặc Tất cả; lọc theo Tiền mặt, Chuyển khoản, Ghi nợ, Đã hủy; gõ tìm khách, sản phẩm, số điện thoại hoặc mã đơn (tìm trong tất cả đơn). Bấm vào một đơn để xem chi tiết, in hóa đơn, sửa hoặc hủy. Danh sách chỉ vẽ 60 đơn một lần, bấm "Xem thêm" để mở thêm cho máy chạy nhẹ.
- **Cài đặt:** màn hình đầu có thẻ cơ sở, lưới Quản lý và các nhóm Cửa hàng, Cá nhân hóa, Hệ thống. Bấm một dòng để vào trang riêng, bấm "Quay lại" (hoặc vuốt từ mép trái) để về.
- **Giá sỉ và giá vốn** trong form sản phẩm để trống khi chưa có, không còn số 0 mặc định.
- Trang Bán hàng và Tổng quan không còn danh sách đơn gần nhất.
- **Thanh menu dưới** còn 5 nút (Tổng quan, Bán hàng, Sản phẩm, Cài đặt, Tài khoản) và nằm sát đáy hơn. Muốn tìm kiếm thì thêm lối tắt **Tìm kiếm** vào Tổng quan (bánh răng > Lối tắt).
- Hộp **Tùy chỉnh Tổng quan** gọn hơn, chạm ra ngoài để đóng.


---

## Bản v20: kho tự động theo công thức, kiểm kê, giao diện xanh dương

**Cập nhật:** tải lên GitHub (ghi đè) `index.html` và `sw.js`, và `manifest.json` (đổi màu thanh trạng thái sang xanh dương). Không cần chạy lại SQL, không cần đổi `config.js`; dữ liệu cũ giữ nguyên.

### Hai cách quản lý nguyên liệu (bật/tắt trong Cài đặt > Kho và giá vốn)
- **Ghi tay (cách cũ):** bạn tự ghi "Xuất dùng" và "Hao hụt" trong trang Nguyên liệu. Giá vốn tính theo sản phẩm hoặc theo nguyên liệu như trước.
- **Tự động theo công thức (cách mới):**
  1. Mở từng sản phẩm, kéo xuống mục **Công thức nguyên liệu**, thêm các nguyên liệu và số lượng cần cho **1 đơn vị** sản phẩm (ví dụ 1 kg giò lụa cần 0,8 kg Thịt Heo và 0,1 kg Mỡ Heo). Chọn tên nguyên liệu từ danh sách để trùng với kho. App hiện luôn giá vốn ước tính và lãi gộp theo công thức.
  2. Bật "Tự động theo công thức" trong Cài đặt, chọn **ngày áp dụng** (mặc định hôm nay).
  3. Từ ngày đó, mỗi đơn bán xong kho tự trừ nguyên liệu và tự ra **xuất dùng**; đơn hủy hoặc hàng trả tự hoàn lại kho. Không cần ghi tay xuất dùng nữa (trang Nguyên liệu > Xuất dùng có bảng "Xuất dùng tự động" để xem).
  4. Nguyên liệu vẫn phải **Nhập kho** như bình thường để có giá bình quân.
  5. Sản phẩm chưa có công thức tạm tính giá vốn theo "Giá vốn" của sản phẩm. Cài đặt cho biết còn bao nhiêu sản phẩm chưa có công thức.
- Chuyển qua lại **bất cứ lúc nào**, không mất dữ liệu. Đơn trước ngày áp dụng vẫn tính theo cách cũ. Đổi công thức sẽ tính lại các đơn từ ngày áp dụng trở đi.

### Kiểm kê kho (dùng được ở cả hai cách)
Trang Nguyên liệu > nút **Kiểm kê kho**: chọn ngày, đếm kho thực tế và nhập vào cột "Thực tế" (hoặc bấm "Điền sẵn số theo sổ sách" rồi chỉ sửa món lệch). Nguyên liệu để trống sẽ bỏ qua.
- Thiếu so với sổ sách: tự ghi thành **hao hụt**, tính theo giá bình quân, trừ vào lợi nhuận ròng.
- Dư so với sổ sách: cộng lại vào kho và giảm hao hụt tương ứng.
- Phiếu kiểm kê hiện trong tab Hao hụt (nhãn "Kiểm kê"). Chạm vào để xem hoặc **xóa cả đợt** nếu nhập sai, rồi kiểm kê lại. Nên kiểm kê cuối ngày hoặc cuối tuần.

### Giao diện
- Màu chính đổi sang **xanh dương**; icon toàn app dùng cùng một kiểu nét và ô màu đặc như trang Cài đặt; bỏ các emoji.
- **Biểu đồ hai màu:** Tổng quan so sánh *Kỳ này* (xanh) với *Kỳ trước* (cam). Thống kê (quản trị) có hai chế độ: *Thu & lãi* (Doanh thu xanh, Lợi nhuận cam) và *So kỳ trước*. Nhân viên chỉ thấy *So kỳ trước*.

### Bản v20.1: chọn nhiều đơn, in hoặc gửi hóa đơn gộp
Vào **Đơn hàng**, bấm nút **Chọn đơn** (cạnh nút Excel). Trên mỗi đơn có ô tích; đơn đã hủy không chọn được.
- **Chọn khách:** chọn tên khách (gõ không dấu cũng tìm được, ví dụ "teo"). App chỉ hiện đơn của khách đó trong tháng (hoặc "Tất cả" nếu tháng này khách chưa mua) và tích sẵn toàn bộ.
- **Chọn tất cả:** chọn mọi đơn đang hiển thị (kể cả khi bạn đang tìm bằng ô tìm kiếm). **Chỉ đơn nợ:** chỉ chọn các đơn ghi nợ, tự chuyển sang xem tất cả thời gian. **Bỏ chọn:** xóa các lựa chọn.
- Thanh phía dưới cho biết số đơn và tổng tiền. Bấm **In / Gửi**: chọn nội dung (**Chi tiết từng đơn** hoặc **Tổng hợp sản phẩm**) và khổ giấy, rồi in qua trình duyệt, in Bluetooth, hoặc gửi Zalo, SMS, Chia sẻ, Sao chép.
- Hóa đơn gộp (bảng kê) ghi từng đơn, tổng tiền, **đã thanh toán** và **còn nợ**. Nếu đã cài tài khoản ngân hàng và khách còn nợ thì có mã QR đúng số tiền nợ.
- Bấm **Xong** để thoát chế độ chọn. Rời trang Đơn hàng cũng tự thoát.
