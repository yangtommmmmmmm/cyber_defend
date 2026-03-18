# 使用 openai 的 API 來生成文本
import openai
from dotenv import load_dotenv # 載入 dotenv 套件
import os

load_dotenv() # 載入環境變數

input_string = "請跟我講述SQL Injection攻擊是什麼?"
model_name = "gpt-4o-mini"

# 從環境變數中取得 API 金鑰，並且設定給 openai
openai.api_key = os.getenv("OPENAI_API_KEY")

client = openai.OpenAI() # 建立 OpenAI 客戶端
completion = client.chat.completions.create(
    model=model_name,
    messages=[
        {
            "role":"system",
            "content":"你是一個很厲害的資安技術專家，請用繁體中文回答問題"
        },
        {
            "role": "user",
            "content": input_string
        }
    ]
)

# 印出回傳的結果
print(completion.choices[0].message.content)
