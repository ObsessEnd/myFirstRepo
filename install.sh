#!/bin/bash
# ==============================================================================
# One-Line Fast Installer for Terminal AI (Google Gemini 3.8 & 3.5 Lite)
# ==============================================================================

echo "⏳ [1/4] Tối ưu kết nối mạng..."
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1 >/dev/null 2>&1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1 >/dev/null 2>&1

echo "⏳ [2/4] Kiểm tra và cài đặt Python / SDK google-genai..."
sudo apt update -y >/dev/null 2>&1
sudo apt install -y python3-pip python3 >/dev/null 2>&1
pip3 install google-genai --break-system-packages >/dev/null 2>&1 || pip3 install google-genai >/dev/null 2>&1

echo "⏳ [3/4] Cấu hình mã nguồn AI..."
cat << 'EOF' > ~/.q.py
#!/usr/bin/env python3
import sys
import base64
from google import genai

KEY_1 = base64.b64decode("QVEuQWI4Uk42SW4wR1F1VklGUUhKcVUxNTc4emd2aUgxZDF3dFQza09XOTFDMUgwNG1HLUE=").decode()
KEY_2 = base64.b64decode("QVEuQWI4Uk42S0R6X3hDeUVEbndHREp2TTliX182aEtlNGVJZzBsR2tOaWlHUTB5R0lLRUE=").decode()

PROMPT_RULE = (
    "Bạn là một trợ lý dòng lệnh Linux chuyên gia. Quy tắc phản hồi:\n"
    "1. Trực diện, không chào hỏi, không mở bài, không kết bài.\n"
    "2. Khi yêu cầu viết code, script, giải bài tập: Phải viết ĐẦY ĐỦ VÀ CHÍNH XÁC toàn bộ logic của đề bài (có 'read', 'if/else', vòng lặp hoàn chỉnh, không được cắt xén bớt bước).\n"
    "3. Đối với câu lệnh đơn lẻ tra cứu nhanh (như 'xem ip', 'xem ram') thì trả về 1 dòng lệnh duy nhất không bọc markdown.\n"
    "4. Khi được hỏi 'là gì', 'giải thích', 'tại sao', chỉ giải thích ngắn gọn 1-2 câu."
)

FAST_MODEL = "gemini-3.5-flash-lite"
HEAVY_MODEL = "gemini-3.8-flash"

def stream_query(query, key, model=FAST_MODEL):
    client = genai.Client(api_key=key)
    res_stream = client.models.generate_content_stream(
        model=model,
        contents=query,
        config={"system_instruction": PROMPT_RULE, "temperature": 0.1}
    )
    for chunk in res_stream:
        if chunk.text:
            print(chunk.text, end="", flush=True)
    print()

def run(query, mode="auto"):
    model_to_use = FAST_MODEL
    lower_q = query.lower()
    if any(k in lower_q for k in ["script", "viết", "kiểm tra", "vòng lặp", "if", "else", "hàm", "thuật toán"]):
        model_to_use = HEAVY_MODEL

    if mode == "1":
        try:
            stream_query(query, KEY_1, HEAVY_MODEL)
        except Exception as e:
            print(f"[Key 1 Error]: {e}")
        return

    if mode == "2":
        try:
            stream_query(query, KEY_2, HEAVY_MODEL)
        except Exception as e:
            print(f"[Key 2 Error]: {e}")
        return

    for k in [KEY_1, KEY_2]:
        try:
            stream_query(query, k, model_to_use)
            return
        except Exception:
            continue
    print("Error: Cả 2 Key đều bận.")

if __name__ == "__main__":
    args = sys.argv[1:]
    mode = "auto"
    if len(args) > 0 and args[0] in ["--1", "--2", "--auto"]:
        mode = args[0].replace("--", "")
        args = args[1:]

    if len(args) > 0:
        run(" ".join(args), mode)
    else:
        try:
            client = genai.Client(api_key=KEY_1)
            chat = client.chats.create(
                model=FAST_MODEL,
                config={"system_instruction": PROMPT_RULE, "temperature": 0.1}
            )
            while True:
                cmd = input("> ")
                if cmd.strip().lower() in ["exit", "quit", "q"]:
                    break
                if not cmd.strip():
                    continue
                stream = chat.send_message_stream(cmd)
                for chunk in stream:
                    if chunk.text:
                        print(chunk.text, end="", flush=True)
                print()
        except (KeyboardInterrupt, EOFError):
            print()
EOF

chmod +x ~/.q.py
echo 123 | sudo -S cp ~/.q.py /usr/local/bin/q >/dev/null 2>&1
echo 123 | sudo -S cp ~/.q.py /usr/local/bin/ask >/dev/null 2>&1
echo 123 | sudo -S cp ~/.q.py /usr/local/bin/h >/dev/null 2>&1

echo "✨ [4/4] Cài đặt thành công 100%! Gõ 'q' hoặc 'ask' để bắt đầu sử dụng."
