# Hướng dẫn lấy Token Agora (App đăng kiểm)

Project dùng **Secure Mode: APP ID + Token**. Cần lấy token từ Console để gọi thoại và chat trong app.

---

## 1. Token cho GỌI THOẠI (RTC)

1. Vào [Agora Console](https://console.agora.io/) → project **App đăng kiểm**.
2. Ở phần **Security** (Primary Certificate):
   - Bấm **Generate Temp Token**.
   - **Channel Name:** nhập tên kênh (vd: `order_29A12345` hoặc `test_call`). App sẽ dùng cùng tên khi join.
   - **UID:** nhập số (vd: `1`).
   - Generate → **Copy** token.
3. Dán token vào file `lib/config/agora_config.dart`:
   - Gán vào `rtcToken` (thay cho chuỗi rỗng `''`).

**Lưu ý:** Temp token có thời hạn. Khi hết hạn cần generate lại. Production nên lấy token từ backend.

---

## 2. Token cho CHAT (Agora Chat)

1. Trong project **App đăng kiểm**, sidebar bên trái chọn **Chat**.
2. **Kích hoạt Chat** (nếu đang Inactive):
   - Chọn **Data Center** gần user (vd: Singapore hoặc Vietnam nếu có).
   - Bấm Activate (lưu ý: sau khi activate không đổi được Data Center).
3. Phần **Chat User Temp Token**:
   - **User ID:** nhập ID user chat (vd: `customer_1` cho app khách, `staff_1` cho nhân viên).
   - Bấm Generate → **Copy** token.
4. Dán vào `lib/config/agora_config.dart`:
   - `chatUserId` = đúng User ID vừa nhập (vd: `customer_1`).
   - `chatToken` = token vừa copy.

Để **hai bên chat được** (khách ↔ nhân viên): tạo 2 user (vd: `customer_1`, `staff_1`), mỗi user generate một Chat User Temp Token và đăng nhập tương ứng ở mỗi app/thiết bị.

---

## 3. Chạy thử

- **Gọi thoại:** Mở màn Theo dõi đơn → Gọi → Chọn "Gọi trong app" → app join kênh RTC. Để nghe thấy nhau cần **2 thiết bị** (hoặc 2 user) cùng join **một channel name** và mỗi bên có token tương ứng (cùng channel).
- **Chat:** Sau khi điền `chatUserId` + `chatToken`, mở màn Theo dõi đơn → nút Chat → đăng nhập Agora Chat và load lịch sử với nhân viên (`staff_1`). Gửi/nhận tin realtime. Bên nhân viên dùng app (hoặc SDK) đăng nhập với User ID `staff_1` và token tương ứng để trả lời.

---

## 4. Production

- **RTC:** Backend tạo token theo [Agora Token Server](https://docs.agora.io/en/video-calling/develop/authentication-workflow?platform=flutter) (channel name + uid), app gọi API lấy token rồi join.
- **Chat:** Backend cấp Chat token cho từng user (theo userId), app không hardcode token.
