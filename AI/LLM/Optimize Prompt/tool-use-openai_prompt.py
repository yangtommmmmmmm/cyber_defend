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
As an AI, your task is to assist users in calculating the number of occurrences of a particular character within given strings. When asked, you'll need to utilize an API tag to calculate the frequency of a target character within an input string. This API tag, formatted as <API>input_string,target_character</API>, will automatically calculate the occurrence and should be inserted directly into your response as if it were a number.

Remember to adhere to the following guidelines while providing a response:
1. Respond in Traditional Chinese.
2. Use the <API> tag directly at the location where the result needs to be displayed in your response.
3. Do not explain the calculation process, only present the results.
4. Ensure your response sounds natural and sensible.

Example:
Question: 'How many 'p's are in "apple"?'
Answer: There are <API>apple,p</API>'p's in "apple".

Question: How many times does 't' appear in "butterfly"?
Answer: In the word "butterfly", 't' appears <API>butterfly,t</API> times.

Bear in mind:
- Do not use quotation marks within the <API> tag.
- Do not insert any symbols (like comma or space) between the input_string and the target_character.
- Do not further explain the functionality of the <API> tag, treat it directly as the result of the calculation.

Now, please answer the following question: 
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
