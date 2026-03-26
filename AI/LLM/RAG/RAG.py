from llama_index.core import VectorStoreIndex, SimpleDirectoryReader
from llama_index.core import StorageContext, load_index_from_storage
from llama_index.core import PromptTemplate
from dotenv import load_dotenv
from rich import print
import chromadb
import os

load_dotenv()

INDEX_PATH = "index"

# store if not exist
if not os.path.exists(INDEX_PATH):
    documents = SimpleDirectoryReader("data").load_data()
    for doc in documents:
         doc.text = doc.text.replace("跳到主要內容區\n學生事務長信箱\n聯絡我們\n網站地圖\nEnglish\n本校首頁\n回首頁\n", "")
    index = VectorStoreIndex.from_documents(documents)
    index.storage_context.persist(INDEX_PATH)

else:
    # rebuild storage context
    storage_context = StorageContext.from_defaults(persist_dir=INDEX_PATH)
    # load index
    index = load_index_from_storage(storage_context=storage_context)


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

response = query_engine.query("補宿費用計算？")
print(response.response)
