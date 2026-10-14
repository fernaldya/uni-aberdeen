import os
import json
import streamlit as st
from datetime import datetime
from langchain_community.vectorstores import Chroma
from langchain_community.embeddings import HuggingFaceEmbeddings
from langchain_community.llms import Ollama
from langchain.chains import create_history_aware_retriever, create_retrieval_chain
from langchain.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage
from ingest_helpers import parse_pdf
from __init__ import CHROMA_DIR, MANIFEST_FILE

DATA_DIR = '../'
CHAT_LOG_FILE = 'chat_history.jsonl'


st.set_page_config(page_title='Uni QnA', page_icon='📚', layout='wide')


# -----------------------------------------------------------------------------
# 1. SIDEBAR: RE-INDEXER CONTROL PANEL
# -----------------------------------------------------------------------------
with st.sidebar:
    st.header("⚙️ Local Notes Re-indexer")

    # Scan for existing PDFs in each course folder in DATA_DIR
    existing_pdfs = []
    if os.path.exists(DATA_DIR):
        for root, _, files in os.walk(DATA_DIR):
            if 'uni-aberdeen' in root:
                continue
            for file in files:
                if file.endswith('.pdf'):
                    existing_pdfs.append(os.path.join(root, file))

    if existing_pdfs:
        selected_paths = st.multiselect(
            'Select notes to index',
            options=existing_pdfs,
            format_func=lambda x: os.path.relpath(x, DATA_DIR)
        )

        if st.button('Index Selected PDFs'):
            for pdf_path in selected_paths:
                # Derive course tag from parent folder name
                course_tag = os.path.basename(os.path.dirname(pdf_path))

                # Index the PDF with course tag
                with st.spinner(f'Indexing {os.path.basename(pdf_path)}...'):
                    result = parse_pdf(pdf_path, course_tag)
                    if result['status'] == 'success':
                        st.success(f'✓ Indexed: {result["message"]}')
                    else:
                        st.error(f'✗ Failed: {result["message"]}')

            st.cache_resource.clear()

    else:
        st.info('No PDF files found in the specified directory.')


# -----------------------------------------------------------------------------
# 2. RAG PIPELINE SETUP (Gemma + ChromaDB)
# -----------------------------------------------------------------------------
st.title('📚 University Notes Assistant')

@st.cache_resource
def get_retriever():
    embeddings = HuggingFaceEmbeddings(model_name='BAAI/bge-small-en-v1.5')
    vectorstore = Chroma(persist_directory=CHROMA_DIR, embedding_function=embeddings)
    return vectorstore.as_retriever(search_kwargs={'k': 4})

try:
    retriever = get_retriever()
except Exception:
    st.warning("Vector database is empty. Please select and re-index notes in the sidebar.")
    st.stop()

# Initialize the LLM (Gemma on Ollama)
llm = Ollama(model='gemma2:9b')

# History-Aware Reformulation Prompt
contextualization_q_sys_prompt = (
    'Given a chat history and the latest user question '
    'which might reference context in the chat history '
    'formulate a standalone question which can be understood '
    'without the chat history. Do NOT answer the question, '
    'just reformulate it if needed and otherwise return as it is.'
)

contextualize_q_prompt = ChatPromptTemplate.from_messages([
    ('system', contextualization_q_sys_prompt),
    MessagesPlaceholder(variable_name='chat_history'),
    ('human', '{input}')
])

history_aware_retriever = create_history_aware_retriever(
    llm,
    retriever,
    contextualize_q_prompt
)

# Gemma 2 Answer System Prompt
system_prompt = (
    "You are an academic assistant for university notes review.\n"
    "Answer the user's question using ONLY the context provided.\n"
    "If the answer is not in the context, say 'I couldn't find it in your notes'.\n"
    "Do not use any external knowledge nor assume or extrapolate beyond what is written.\n"
    "Always cite the source, document, and page number when answering.\n\n"
    "Context:\n{context}\n"
)

answer_prompt = ChatPromptTemplate.from_messages([
    ('system', system_prompt),
    MessagesPlaceholder(variable_name='chat_history'),
    ('human', '{input}')
])

question_answer_chain = create_stuff_documents_chain(llm, answer_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)


# -----------------------------------------------------------------------------
# 3. CHAT UI WITH PERSISTENCE
# -----------------------------------------------------------------------------
