import openai
from dotenv import load_dotenv
import os

# 1. 載入環境變數
load_dotenv()
openai.api_key = os.getenv("OPENAI_API_KEY")
client = openai.OpenAI()

# 2. 設定模型與題目資訊
model_name = "gpt-4o-mini"

# 題目描述
problem_statement = """
我正在建造太陽能設施，需要計算第一年的總成本：
- 土地成本：每平方英尺 $100
- 太陽能板：每平方英尺 $250
- 維護合約：每年固定 $100,000，外加每平方英尺 $10 的變動費用
請以安裝面積 x (平方英尺) 為函數，寫出第一年的總成本公式。
"""

# 學生的錯誤解答
student_solution = """
假設 x 為面積：
1. 土地成本: 100x
2. 太陽能板成本: 250x
3. 維護成本: 100,000 + 100x (這裡故意寫錯，應該是 10x)
總成本: 100x + 250x + 100,000 + 100x = 450x + 100,000
"""

# 3. 呼叫 API
completion = client.chat.completions.create(
    model=model_name,
    messages=[
        {
            "role": "system",
            "content": "你是一位嚴謹的老師。請先『自己完整計算出正確答案』，然後再將你的答案與學生的答案進行比對。在你自己算完之前，不要輕易判斷學生的對錯。如果學生錯了，請指出具體錯誤在哪裡。"
        },
        {
            "role": "user",
            "content": f"題目：\n{problem_statement}\n\n學生的解答：\n{student_solution}"
        }
    ]
)

# 4. 印出結果
print("--- 模型思考與批改結果 ---")
print(completion.choices[0].message.content)
