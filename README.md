# Bộ Lạc Tiền Sử

Game sinh tồn 2D offline, ưu tiên Android, phát triển bằng Godot 4.

## Chạy thử
1. Cài Godot Engine 4.x.
2. Chọn Import và mở thư mục chứa file `project.godot`.
3. Mở project và nhấn F6/F5 để chạy scene chính.

## Prototype hiện tại
- Nhân vật di chuyển bằng phím mũi tên hoặc WASD.
- Camera bám theo nhân vật.
- Bản đồ thử nghiệm có nền và các điểm tài nguyên minh họa.

## Hệ thống bộ lạc mới
- Nhà ở có 5 cấp, tăng sức chứa dân cư; nguyên liệu gỗ/đá và tiến độ được lưu offline.
- Khu huấn luyện chiến binh: mỗi lượt tốn 5 lương thực, mất 90 giây, tăng 5 sức mạnh và 5 thể lực (tối đa 100); hàng chờ được lưu offline.
- Hai hệ thống được đăng ký làm Autoload trong `project.godot`.
- Bảng quản lý bộ lạc trên HUD Android: xem dân số, đổi dân làng đang chọn, dựng/nâng cấp nhà, phân công chỗ ở, chuyển gỗ/đá từ túi đồ vào kho bộ lạc và bắt đầu huấn luyện.
- Nút `BỘ LẠC` được tích hợp vào HUD hiện tại; bảng quản lý có thể mở/đóng khi chơi.

## Lộ trình
1. Vòng lặp sinh tồn: máu, đói, khát.
2. Thu thập gỗ, đá và thức ăn.
3. Chế tạo công cụ.
4. Động vật tiền sử và AI người man rợ.
5. Các vùng khám phá, sự kiện đột kích và lưu game.

Đây là bộ khung khởi đầu; chưa phải bản APK hoàn chỉnh.


### Sửa lỗi và độ ổn định hệ thống bộ lạc
- Dân cư mới được lưu ngay sau khi thêm, tránh mất dữ liệu khi thoát game.
- TribePopulation cung cấp get_resident() để các hệ thống khác kiểm tra cư dân còn sống.
- Phân nhà kiểm tra cư dân hợp lệ, dọn phân công của người đã chết và cho phép chuyển nhà khi nhà đích còn đủ chỗ.
- Hàng chờ huấn luyện được lưu tiến độ định kỳ mỗi 5 giây; dữ liệu hàng chờ không hợp lệ được loại khi tải.
- Các thay đổi đã được ghi lên nhánh main. Chưa chạy kiểm thử Godot runtime hoặc build APK trong môi trường hiện tại.
