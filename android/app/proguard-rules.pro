# Agora Chat SDK tham chiếu các push vendor (OPPO, Meizu, Vivo, Xiaomi) tùy chọn.
# App không include các SDK đó nên R8 báo missing class. Bỏ qua cảnh báo để build release.
-dontwarn com.heytap.msp.push.**
-dontwarn com.meizu.cloud.pushsdk.**
-dontwarn com.vivo.push.**
-dontwarn com.xiaomi.mipush.sdk.**
