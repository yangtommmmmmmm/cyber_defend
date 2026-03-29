# 使用openai 的 API來生成文本
import openai
from dotenv import load_dotenv #載入 dotenv套件
import os
import tiktoken

load_dotenv() #載入環境變數

#從環境變數中取得API金鑰，並且設定給openai
openai.api_key = os.getenv("OPENAI_API_KEY")

#建立OpenAI 客戶端
client = openai.OpenAI()

model_name = "gpt-4o-mini"
#使用tiktoken 建立編碼器
encoding = tiktoken.encoding_for_model(model_name)

# 計算 input_string 中 target_character 的數量
def calculate_letter_count(input_string, target_character):
    return input_string.count(target_character)

def format_string(ai_response_string):
    while True:
        start_index = ai_response_string.find("<API>") # 找到 <API> 的開始位置，如果找不到會回傳 -1
        if start_index == -1:
            break
        end_index = ai_response_string.find("</API>", start_index) # 找到 </API> 的結束位置
        if end_index == -1:
            break
        api_content = ai_response_string[start_index+5:end_index] # 取得 API 內容
        input_string, target_character = api_content.split(',') # 分割 input_string 和 target_character
        letter_count = calculate_letter_count(input_string.strip(), target_character.strip()) # 計算字母數量
        ai_response_string = ai_response_string[:start_index] + str(letter_count) + ai_response_string[end_index+6:] # 把計算結果放回 ai_response_string 中
    return ai_response_string

# 提示的 propmt
prompt = '''
你將幫助使用者計算字串中特定字母或字符的數量。

這是使用者的問題：
<user_question>
{{USER_QUESTION}}
</user_question>

你的任務是理解使用者想要計算什麼字串中的什麼字符，然後使用特定的 API 格式來表達答案。

重要規則：
1. 當你需要表達計算結果時，必須使用以下格式：<API>input_string, target_character</API>
2. 將 input_string 替換成要計算的完整字串
3. 將 target_character 替換成要計算的目標字母或字符
4. **不要**在 input_string 或 target_character 外面加上引號
5. **不要**在 input_string 和 target_character 之間加上逗號、空格或任何其他符號
6. 你可以用自然的繁體中文語句來潤飾你的回答，但不需要解釋計算過程
7. 整個回答必須使用**繁體中文**

格式範例：
- 正確：<API>hello world, l</API>
- 錯誤：<API>"hello world", "l"</API>
- 錯誤：<API>hello world , l</API>
- 錯誤：<API>"hello world","l"</API>

回答範例：
如果使用者問「apple 這個字有幾個 p？」
你應該回答：「apple 這個字中有 <API>apple, p</API> 個 p。」

如果使用者問「How many 'o' in 'good'?」
你應該回答：「good 這個字中有 <API>good, o</API> 個 o。」

現在請用繁體中文回答使用者的問題，並使用正確的 API 格式。
'''
# 初始化對話歷史
messages = [
    {
        "role": "system",
        "content": prompt
    }
]


while True:
    user_input = input("你:")

    #將用戶輸入加到歷史對話中
    messages.append({"role": "user","content": user_input})

    #如果用戶輸入 '再見'，結束對話
    if user_input.lower() == '再見':
        print("AI:再見!期待與您再相逢!")
        break

    total_tokens = sum(len(encoding.encode(msg["content"])) for msg in messages)

    #當token超過10000時，移除最早的消息
    while total_tokens > 10000:
        messages.pop(1) #移除最早的用戶或AI回應
        total_tokens = sum(len(encoding.encode(msg["content"])) for msg in messages)

    # 發送請求給 OpenAI API
    completion = client.chat.completions.create(
        model=model_name,
        messages=messages
        )

    # 獲取 AI 的回應
    ai_response = completion.choices[0].message.content
    # 將AI的回應加到對話歷史中
    messages.append({"role": "assistant", "content": ai_response})

    ai_response = format_string(ai_response)
    # 印出 AI 的回應
    print(f"AI：{ai_response}")
