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


### Hệ thống nghề nghiệp bộ lạc
- Thêm 5 nghề có thể phân công cho cư dân trưởng thành: thợ săn, người hái lượm, nông dân, thợ chế tác và chiến binh.
- Mỗi 30 giây, mỗi người được phân nghề tạo sản lượng tương ứng vào kho bộ lạc.
- Số lượng lao động theo nghề và kho sản phẩm được lưu offline.
- Bảng quản lý bộ lạc có nút đổi nghề cho cư dân đang chọn và hiển thị số lượng nghề cùng kho sản phẩm.


## Hệ thống khám phá vùng đất
- RegionSystem quản lý 6 khu vực: đồng bằng bộ lạc, rừng nguyên sinh, đồng cỏ, đầm lầy, hang động và miền băng tuyết.
- Mỗi khu vực có tọa độ, bán kính phát hiện, cấp nguy hiểm, khí hậu, tài nguyên, thú đặc trưng và nguy cơ riêng.
- Khu vực được nhận diện theo vị trí người chơi; lần đầu bước vào sẽ lưu dấu khám phá offline.
- HUD hiển thị khu vực hiện tại, cấp nguy hiểm, khí hậu, tài nguyên, thú đặc trưng, nguy cơ và tiến độ khám phá.
- Bản đồ hiển thị vùng màu để định hướng hành trình. Danh mục tài nguyên/thú hiện là dữ liệu vùng; phân bố tài nguyên và sinh vật riêng theo biome sẽ được triển khai ở bước tiếp theo.


## Sinh tài nguyên và thú theo vùng
- Khi người chơi bước vào một biome, BiomeEncounterDirector tạo các điểm thu thập và động vật phù hợp với vùng đó.
- Rừng có gỗ, quả dại, thảo dược, da thú; đồng cỏ có thức ăn, xương, đá lửa và voi ma mút; đầm lầy có nước, lau sậy, thảo dược; hang động có đá, quặng, xương và thú hang; miền băng có băng, thịt, da và thú lớn.
- Các điểm sinh theo vùng được dọn khi rời vùng để tránh tích tụ quá nhiều đối tượng; sinh vật và tài nguyên minh họa ban đầu trong khu vực trung tâm vẫn được giữ.
- ResourceNode hỗ trợ thêm loại tài nguyên mới và màu nhận diện riêng.


## Trại man rợ theo vùng
- Mỗi biome có một trại man rợ riêng với tên, vị trí và lực lượng bảo vệ phù hợp cấp nguy hiểm.
- Trại gồm lính canh và một thủ lĩnh; tiêu diệt toàn bộ lực lượng sẽ chiếm được trại.
- Phần thưởng chiếm trại: 15 lương thực, 10 dụng cụ và 5 chiến lực bộ lạc.
- Tiến độ trại đã chiếm được lưu offline; trại đã dọn sẽ không tự xuất hiện lại khi quay lại vùng.
- Hệ thống được tích hợp vào scene chính qua BarbarianCampDirector.

## Lưu túi đồ offline
- InventorySystem tự tải dữ liệu khi nhân vật được tạo và lưu ngay sau mỗi lần nhận hoặc tiêu hao vật phẩm.
- Các loại tài nguyên mới theo biome (quặng, đá lửa, thảo dược, da, xương, lau sậy, băng và thịt) được lưu dưới dạng ID linh hoạt, không cần whitelist.
- Dữ liệu túi đồ được lưu riêng trong user://bo_lac_inventory.cfg.


## Hang động có thể khám phá
- Hang Động Cổ Xưa có cổng vào tại khu vực cavern; chạm vào vòng đánh dấu để đi xuống.
- Khu vực bên trong là một phòng hang riêng biệt trên cùng bản đồ offline, có giới hạn di chuyển và lối ra để quay về mặt đất.
- Hang có gấu hang và hổ răng kiếm canh giữ; động vật được tạo khi người chơi bước vào và dọn khi rời đi.
- Hệ thống được tích hợp vào Main.tscn bằng CaveSystem.gd.


## Trang bị sinh tồn và hiểm họa môi trường
- Áo da thú giảm mạnh sát thương lạnh tại Miền Băng Tuyết.
- Đuốc giảm sát thương do bóng tối và giá lạnh trong Hang Động Cổ Xưa.
- Thuốc giải thảo dược được tự dùng khi bước vào Đầm Lầy, bảo vệ khỏi độc tố trong 90 giây.
- Người chơi chịu sát thương môi trường theo thời gian nếu thiếu trang bị phù hợp.
- Công thức chế tạo: áo da (8 da + 3 xương), thuốc giải (3 thảo dược + 2 quả dại), đuốc (3 gỗ + 2 lau sậy).
- HUD có các nút chế tạo trang bị sinh tồn. Vật phẩm được lưu trong túi đồ offline.


## Thuần hóa và thú đồng hành
- Người chơi có thể thuần hóa thú tiền sử ở khoảng cách gần bằng thức ăn phù hợp.
- Sói cần 2 thịt; hổ răng kiếm cần 5 thịt; gấu hang cần 6 thịt; voi ma mút cần 8 lương thực.
- Giới hạn đội hình là 3 thú đồng hành cùng lúc.
- Thú đã thuần hóa đi theo người chơi và tự động tấn công kẻ địch gần đó; không còn bị nhận diện là thú địch.
- HUD Android có nút THUẦN HÓA THÚ và hiển thị yêu cầu thức ăn khi chưa đủ.
- Trạng thái thú đồng hành, cấp nâng cấp, máu, vị trí tương đối và thú đang cưỡi hiện được lưu offline trong `user://bo_lac_companions.cfg`.


## Thú cưỡi và nâng cấp thú đồng hành
- Có thể cưỡi thú đã thuần hóa khi đứng gần và xuống thú bằng cùng một nút trên HUD.
- Tốc độ cưỡi theo loài: sói x1,6; hổ răng kiếm x1,8; gấu hang x1,15; voi ma mút x1,35.
- Thú đồng hành có thể nâng cấp tối đa cấp 3; mỗi cấp cần 5 xương và 3 da thú, tăng máu tối đa, sát thương và tốc độ.
- Thú đã thuần hóa được giữ lại khi rời Hang Động Cổ Xưa; chỉ thú hoang trong hang mới bị dọn.
- Đội thú được khôi phục khi mở game; dữ liệu tự lưu sau thay đổi và định kỳ 10 giây.


## Lưu thú đồng hành
- Thú đã thuần hóa, loài, cấp nâng cấp, lượng máu, vị trí tương đối và trạng thái đang cưỡi được lưu trong `user://bo_lac_companions.cfg`.
- Khi mở game, tối đa 3 thú đã lưu được khôi phục cùng người chơi.
- Dữ liệu thú được tự lưu sau khi thuần hóa, nâng cấp, cưỡi/xuống thú; đồng thời tự lưu định kỳ 10 giây và khi nhận yêu cầu đóng game.
- Tệp lưu nằm trong vùng dữ liệu riêng của game trên thiết bị; chưa có đồng bộ đám mây.
