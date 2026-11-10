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


## Sinh sản và trưởng thành của thú
- Có thể cho 2 thú đồng hành trưởng thành cùng loài sinh sản khi cả hai ở gần người chơi.
- Mỗi lần sinh sản tiêu hao 10 lương thực và 5 thịt; cần còn chỗ trong giới hạn đội hình 3 thú.
- Thú con được tạo ngay, có kích thước và sức chiến đấu thấp hơn; sau 5 phút chơi sẽ trưởng thành.
- Tiến độ lớn lên của thú con được lưu offline cùng đội thú và tiếp tục khi mở game lại.
- HUD có nút LAI TẠO THÚ; hiện chỉ hỗ trợ sinh sản cùng loài, chưa có lai chéo.


## Chăm sóc và quản lý đàn thú
- Nút CHO THÚ ĂN / HỒI MÁU chọn thú đồng hành bị thương gần nhất trong phạm vi 165 đơn vị.
- Sói, hổ răng kiếm và gấu hang cần 2 thịt; voi ma mút cần 3 lương thực. Mỗi lần ăn hồi tối đa 40% máu tối đa.
- Nút XEM ĐÀN THÚ hiển thị loài, máu hiện tại, giai đoạn thú con/trưởng thành, cấp nâng cấp và trạng thái cưỡi.
- Việc cho ăn lưu lại lượng máu mới vào tệp lưu thú đồng hành. Đây là hệ thống chăm sóc qua HUD, không thêm cơ chế xây chuồng hay xây căn cứ.


## Kỹ năng chiến đấu và mệnh lệnh thú đồng hành
- Sói có kỹ năng Truy kích nhanh; hổ răng kiếm có Vồ xé; gấu hang có Gấu cuồng nộ; voi ma mút có Dậm nghiền. Mỗi loài có sát thương và nhịp ra đòn riêng.
- Nút THÚ TẤN CÔNG ra lệnh cho thú trưởng thành không cưỡi truy đuổi kẻ địch trong phạm vi phát hiện rộng.
- Nút THÚ BẢO VỆ chuyển cả đội về chế độ hộ vệ, chỉ chủ động đánh kẻ địch áp sát người chơi.
- Nút KỸ NĂNG ĐÀN THÚ xem kỹ năng và mệnh lệnh hiện tại của từng con.
- Mệnh lệnh được lưu offline và khôi phục khi tải đội thú. Thú con không tham chiến; thú đang cưỡi không nhận lệnh tấn công cho đến khi xuống thú.


## Tiến hóa và trang bị thú đồng hành
- Thú trưởng thành có 3 bậc: Thú Đồng Hành (cấp 1), Thú Chiến Tinh Nhuệ (cấp 2), Cổ Thú Thức Tỉnh (cấp 3).
- Cấp 2 và 3 tăng hệ số sát thương kỹ năng; chỉ số máu, sát thương cơ bản và tốc độ tiếp tục tăng theo nâng cấp hiện có.
- Giáp thú chế tạo bằng 6 da + 4 xương, giảm 30% sát thương nhận vào cho thú đã trang bị.
- Bùa nanh chế tạo bằng 6 xương + 3 đá, tăng 15% sát thương kỹ năng.
- Nút TRANG BỊ THÚ tự trang bị các món đang có trong túi cho thú trưởng thành gần nhất. Trang bị và cấp tiến hóa được lưu offline.
- Các thay đổi này chỉ thêm trang bị cho thú đồng hành, không thêm cơ chế xây dựng căn cứ.


## Ổ trứng và ấp nở thú tiền sử
- Khi hai thú trưởng thành cùng loài sinh sản, chúng tạo một trứng thay vì sinh thú con ngay lập tức.
- Trứng cần 180 giây thời gian chơi để ấp; bộ đếm tiếp tục được lưu offline và khôi phục khi mở lại game.
- Nút XEM Ổ TRỨNG hiển thị loài và thời gian còn lại; nút ẤP / NỞ TRỨNG đưa thú con đã đủ thời gian vào đàn.
- Trứng đang ấp cũng chiếm một vị trí trong giới hạn đội hình 3 thú để tránh vượt giới hạn khi nở.
- Thú con sau khi nở tiếp tục cần 5 phút chơi để trưởng thành.


## Đột biến hiếm và thú huyền thoại
- Mỗi lần trứng nở có 12% cơ hội sinh thú Hiếm và 2% cơ hội sinh thú Huyền thoại; các trường hợp còn lại là thú thường.
- Thú Hiếm có +25% máu tối đa, +20% sát thương và +8% tốc độ.
- Thú Huyền thoại có +70% máu tối đa, +55% sát thương và +18% tốc độ.
- Thú hiếm có viền sáng xanh; thú huyền thoại có viền vàng. HUD đàn thú hiển thị phẩm chất và dữ liệu phẩm chất được lưu offline.


## Kỹ năng tối thượng của thú huyền thoại
- Sói Huyền Thoại dùng Bão Truy Kích, đánh lan sang một kẻ địch gần mục tiêu.
- Hổ Răng Kiếm Huyền Thoại dùng Song Trảo Chí Mạng, gây thêm một đòn dồn sát thương lên mục tiêu.
- Gấu Hang Huyền Thoại dùng Chấn Địa Cuồng Nộ, gây sát thương diện rộng quanh bản thân.
- Voi Ma Mút Huyền Thoại dùng Địa Chấn Cổ Đại, gây sát thương diện rộng với bán kính lớn hơn.
- Kỹ năng đặc biệt tự kích hoạt khi chiến đấu, có thời gian hồi riêng 5 giây; bảng KỸ NĂNG ĐÀN THÚ hiển thị tên kỹ năng theo phẩm chất.


## Thức tỉnh Thần Thú
- Chỉ thú Huyền Thoại trưởng thành đã đạt cấp 3 mới có thể thức tỉnh.
- Thức tỉnh tiêu hao 12 xương, 8 quặng và 5 da thú; thú đạt cấp 4 với danh hiệu Thần Thú Giáng Thế.
- Thần Thú nhận thêm 45% máu tối đa, 30% sát thương và 10% tốc độ ở lần tiến hóa cuối; kỹ năng huyền thoại mạnh hơn và hồi chiêu còn 3,5 giây.
- Thần Thú có vòng hào quang vàng sáng riêng; cấp tiến hóa được lưu offline.
- Nút THỨC TỈNH THẦN THÚ chỉ xuất hiện như thao tác trong HUD, không thêm hệ thống xây dựng căn cứ.


## Thú Chúa và hào quang đàn thú
- Người chơi có thể phong một Thần Thú Huyền Thoại cấp 4 trưởng thành gần mình làm Thú Chúa.
- Mỗi đàn chỉ có một Thú Chúa; phong thú mới sẽ thay thế danh hiệu của thú cũ.
- Thú đồng hành trong phạm vi 420 đơn vị quanh Thú Chúa được tăng 15% sát thương kỹ năng và 10% tốc độ di chuyển.
- Thú Chúa có vòng hào quang màu hồng tím và danh hiệu riêng; trạng thái được lưu offline.


## Di truyền trứng và đột biến cổ thú
- Trứng lưu phẩm chất di truyền và đột biến ngay từ lúc sinh sản; dữ liệu được giữ qua lần thoát game.
- Hai bố mẹ Huyền Thoại có 20% cơ hội truyền Huyền Thoại, nếu ít nhất một bố mẹ khác thường thì có cơ hội truyền phẩm chất Hiếm hoặc Huyền Thoại.
- Đột biến gồm Hỏa (tăng sát thương), Băng (tăng máu), Độc (tăng sát thương và tốc độ), Lôi (tăng tốc độ) và Thần (tăng cả ba chỉ số).
- Đột biến Thần rất hiếm và chỉ xuất hiện trên trứng có phẩm chất Huyền Thoại; thú con giữ đột biến khi trưởng thành.
- Ngoại hình thú biến đổi màu và có vòng sáng theo loại đột biến.


### Boss lãnh địa – tiến hóa và cổ vật độc quyền
- Khi boss còn 65% máu, nó triệu hồi hai thú hộ vệ lãnh địa; hộ vệ biến mất khi rời vùng hoặc boss bị hạ.
- Khi boss còn 50% máu, nó tiến hóa một lần: tăng 35% máu tối đa, hồi thêm máu, tăng 30% sát thương và 12% tốc độ.
- Hạ boss nhận thêm một cổ vật riêng theo vùng: `trophy_heartland`, `trophy_primeval_forest`, `trophy_grassland`, `trophy_swampland`, `trophy_cavern`, `trophy_frostlands`. Cổ vật được lưu trong kho bộ lạc để dùng cho hệ thống chế tác/nâng cấp về sau.


### Vũ khí di vật từ Boss lãnh địa
- Sáu cổ vật boss có thể dùng để chế tạo sáu vũ khí riêng: Rìu Ma Mút, Kiếm Răng Hổ, Thương Sấm, Vuốt Đầm Lầy, Chùy Hang và Cung Băng.
- Mỗi công thức yêu cầu đúng cổ vật của vùng tương ứng cùng nguyên liệu đặc trưng; cổ vật bị tiêu hao khi chế tạo.
- Khi cầm vũ khí di vật trong túi, đòn đánh cận chiến dùng sát thương riêng từ 46 đến 68, cao hơn vũ khí đá cơ bản.
- HUD Android có hai hàng nút chế tạo vũ khí di vật; vũ khí và cổ vật đều được lưu trong túi đồ offline.


## Kỹ năng chủ động của sáu vũ khí di vật
- Nút KỸ NĂNG DI VẬT trên HUD kích hoạt kỹ năng của vũ khí di vật mạnh nhất đang có trong túi; mỗi kỹ năng hồi chiêu 8 giây.
- Rìu Ma Mút: Rìu Quét, gây 48 sát thương diện rộng trong bán kính 145.
- Kiếm Răng Hổ: Song Trảo Chí Mạng, dồn 82 sát thương lên một mục tiêu gần.
- Thương Sấm: Sấm Sét Liên Kích, gây 45 sát thương lên tối đa 3 mục tiêu trong tầm 420.
- Vuốt Đầm Lầy: Nọc Độc, gây 35 sát thương và độc 8 sát thương/giây trong 6 giây.
- Chùy Hang: Chấn Địa, gây 58 sát thương trong bán kính 190.
- Cung Băng: Băng Phong Tiễn, gây 32 sát thương và làm chậm 65% trong 4 giây.
- Hiệu ứng độc và làm chậm được xử lý trực tiếp trong EnemyAI; không cần vật phẩm tiêu hao khi kích hoạt kỹ năng.
- Các thay đổi đã được ghi lên nhánh main. Chưa chạy kiểm thử Godot runtime hoặc build APK trong môi trường hiện tại.


## Điều khiển toàn bộ bộ lạc kiểu chiến thuật
- Mỗi cư dân còn sống được tạo thành một đơn vị hiển thị trực tiếp trên bản đồ; màu đơn vị phân biệt chiến binh, thợ săn, người hái lượm và nông dân.
- Có thể chạm/click từng đơn vị để chọn riêng; nút CHỌN CẢ BỘ LẠC chọn toàn bộ cư dân.
- Nút DI CHUYỂN bật chế độ ra lệnh; chạm vị trí trên bản đồ để điều nhóm đã chọn đến đó, các thành viên tự dàn đội hình.
- Nút THEO TÔI tập hợp nhóm đã chọn quanh nhân vật thủ lĩnh; nút BỘ LẠC TẤN CÔNG chuyển nhóm được chọn sang vai trò chiến đấu và tự đánh kẻ địch ở gần.
- Cư dân mới được thêm tự động vào bản đồ; cư dân đã chết được loại khỏi đội hình. Nghề nghiệp được đồng bộ từ hệ thống phân công.
- Đây là nền tảng RTS đầu tiên; các lệnh chuyên sâu như khai thác tài nguyên theo điểm, đội hình, chia tiểu đội và chiến dịch nhiều mũi sẽ tiếp tục được mở rộng.
- Đã ghi thay đổi lên nhánh main; chưa chạy Godot runtime hoặc build APK.


### Cờ tập hợp và lệnh tái tập hợp
- Chọn ĐẶT CỜ TẬP HỢP, sau đó chạm vị trí bất kỳ trên bản đồ để cắm cờ; có thể đặt lại cờ ở vị trí mới.
- Cờ hiển thị bằng cột cờ đỏ và vòng tròn đánh dấu khu vực tập hợp.
- Chọn TẬP HỢP VỀ CỜ để ra lệnh toàn bộ dân làng còn sống di chuyển về đội hình quanh cờ; lệnh này hủy trạng thái tấn công cũ để ưu tiên tập hợp.
- Đồng bộ đơn vị đã sửa để loại bỏ cả cư dân đã chết, không chỉ cư dân bị thiếu dữ liệu.
- Đây là lệnh điều quân RTS; hệ thống nhân vật cũ vẫn được giữ để các tính năng sinh tồn hiện có tiếp tục hoạt động.


### Camera chiến thuật RTS
- Camera được tách khỏi nhân vật Player và đặt trực tiếp dưới Main để không tự động khóa theo nhân vật.
- PC: giữ chuột giữa và kéo để lia bản đồ; lăn bánh xe để phóng to/thu nhỏ.
- Android: bật KÉO BẢN ĐỒ rồi vuốt màn hình để lia camera; tắt chế độ này để chạm chọn đơn vị hoặc ra lệnh.
- Nút VỀ TRUNG TÂM đưa camera về vị trí Player hiện tại.
- Giới hạn zoom hiện tại: 0.55x đến 1.65x.


### Chọn nhiều đơn vị bằng khung kéo
- Trên PC, giữ chuột trái và kéo trên bản đồ để tạo khung chọn; thả chuột để chọn tất cả dân làng nằm trong khung.
- Trên Android, bật nút CHỌN VÙNG rồi kéo ngón tay qua nhóm dân làng; thả tay để xác nhận nhóm được chọn. Tắt CHỌN VÙNG để quay lại thao tác chạm chọn/ra lệnh thông thường.
- Khung chọn có viền xanh trong suốt; các đơn vị được chọn vẫn giữ vòng sáng nhận diện.
- Chế độ chọn vùng, di chuyển và đặt cờ tập hợp được tách biệt để tránh một thao tác kích hoạt nhiều lệnh cùng lúc.
- Chưa chạy kiểm thử Godot runtime hoặc build APK.


### Chia tiểu đội theo nghề nghiệp
- HUD có lệnh chọn riêng Chiến binh, Thợ săn, Người hái lượm, Nông dân và Thợ chế tác.
- Chọn tiểu đội theo nghề sẽ tự bỏ chọn nhóm trước đó; số lượng đơn vị được chọn hiển thị trong thông báo trạng thái.
- Sau khi chọn tiểu đội, có thể dùng các lệnh RTS hiện có như di chuyển, theo thủ lĩnh, tấn công hoặc tập hợp về cờ.
- Nút BỎ CHỌN xóa lựa chọn hiện tại mà không ảnh hưởng đến dân số hay phân công nghề.
- Tiểu đội lấy trực tiếp nghề nghiệp đã phân công trong TribePopulation/TribeJobSystem; khi đổi nghề, đơn vị sẽ thuộc nhóm nghề mới sau lần đồng bộ.
- Chưa chạy kiểm thử Godot runtime hoặc build APK.


### Tự động phòng thủ của chiến binh
- Chiến binh trưởng thành được phân nghề sẽ tự động tuần tra bảo vệ bộ lạc khi không có lệnh di chuyển thủ công.
- Khi phát hiện thú hoang hoặc man rợ áp sát người chơi hay cư dân trong phạm vi 210 đơn vị, chiến binh gần nhất sẽ tiếp cận và tấn công mục tiêu.
- Chiến binh gây 9 sát thương mỗi 1,1 giây khi áp sát; mục tiêu được quét lại định kỳ để tránh truy đuổi các mối đe dọa đã rời xa.
- Lệnh di chuyển thủ công vẫn được ưu tiên; khi hoàn tất, chiến binh tiếp tục tự động phòng thủ.
- Đây là AI phòng thủ tự động, không thay đổi số dân, nghề nghiệp hoặc hệ thống xây dựng.
- Chưa chạy kiểm thử Godot runtime hoặc build APK.


### Đội hình chiến đấu theo vai trò
- Khi ra lệnh BỘ LẠC TẤN CÔNG, các cư dân trưởng thành được chọn tự tìm mục tiêu địch trong phạm vi 520 đơn vị và phối hợp tiếp cận.
- Chiến binh áp sát tuyến đầu, gây 8 sát thương mỗi 1,3 giây.
- Thợ săn giữ khoảng cách chiến đấu khoảng 145 đơn vị, lùi ra nếu bị áp sát và gây 12 sát thương mỗi 1,8 giây.
- Các nghề khác tham gia hỗ trợ ở khoảng cách trung bình với sát thương 5 mỗi 1,6 giây.
- Lệnh di chuyển thủ công hủy chế độ chiến đấu để người chơi giành lại quyền điều khiển; chiến binh sẽ quay lại tự phòng thủ khi không còn lệnh chiến đấu.
- AI đội hình dùng sát thương tầm xa mô phỏng cho thợ săn; chưa có hoạt ảnh/phóng mũi tên riêng.
- Chưa chạy kiểm thử Godot runtime hoặc build APK.
