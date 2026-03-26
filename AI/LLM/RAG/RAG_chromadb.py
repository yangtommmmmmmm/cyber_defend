from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core import StorageContext, load_index_from_storage
from llama_index.core import PromptTemplate
from dotenv import load_dotenv
from rich import print
import chromadb
from llama_index.vector_stores.chroma import ChromaVectorStore
import os

load_dotenv()

# 初始化客戶端，並且選擇向量資料庫的所在路徑
# 有了這個客戶端我們才可以操作資料庫
db = chromadb.PersistentClient(path="./chroma_db")
# 創建集合 (collection)
chroma_collection = db.get_or_create_collection("my_collection")

# 取得 StorageContext
vector_store = ChromaVectorStore(chroma_collection=chroma_collection)
storage_context = StorageContext.from_defaults(vector_store=vector_store)

#判斷集合內裡面是否有沒有東西
if chroma_collection.count() == 0:
    print("資料庫是空的，正在讀取文件並建立索引...")
    documents = SimpleDirectoryReader("data").load_data()
    for doc in documents:
        # 1. 先取得原始文字
        original_text = doc.get_content()
        # 2. 進行字串替換
        cleaned_text = original_text.replace(
            "跳到主要內容區\n學生事務長信箱\n聯絡我們\n網站地圖\nEnglish\n本校首頁\n回首頁\n", "")
        # 3. 使用專用的 setter 方法把乾淨的文字塞回去
        doc.set_content(cleaned_text)

    index = VectorStoreIndex.from_documents(
        documents,
        storage_context=storage_context
    )
else:
    print(f"資料庫已有 {chroma_collection.count()} 筆資料，直接載入索引...")
    # 這裡才是從現有的 vector_store 建立 index 物件
    index = VectorStoreIndex.from_vector_store(
        vector_store,
        storage_context=storage_context
    )

qa_template = (
"""
以下是上下文
---------------------
{context_str}
---------------------
請根據上下文信息回答以下問題，不需要事先知識，並在最後加上一個 "XD" 笑臉符號。
問題: {query_str}
回答: 
"""
)

custom_qa_prompts = PromptTemplate(qa_template)
query_engine = index.as_query_engine()
query_engine.update_prompts(
    {"response_synthesizer:text_qa_template": custom_qa_prompts}
)

response = query_engine.query("補宿申請？")
print(response.response)
