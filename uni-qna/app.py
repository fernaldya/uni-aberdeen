import os
import json
import streamlit as st
from datetime import datetime
from langchain_chroma import Chroma
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_ollama import ChatOllama
from langchain_classic.chains import (
    create_history_aware_retriever,
    create_retrieval_chain,
)
from langchain_classic.chains.combine_documents import create_stuff_documents_chain
from langchain_core.prompts import ChatPromptTemplate, MessagesPlaceholder
from langchain_core.messages import HumanMessage, AIMessage

# pyrefly: ignore[missing-import]
from ingest_helpers import parse_pdf

# pyrefly: ignore[missing-import]
from __init__ import CHROMA_DIR

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.abspath(os.path.join(BASE_DIR, ".."))
CHAT_LOG_FILE = os.path.join(BASE_DIR, "chat_history.jsonl")


st.set_page_config(page_title="Uni QnA", page_icon="📚", layout="wide")


# -----------------------------------------------------------------------------
# 1. SIDEBAR: RE-INDEXER CONTROL PANEL
# -----------------------------------------------------------------------------
with st.sidebar:
    st.header("⚙️ Local Notes Re-indexer")

    # Scan for existing PDFs in each course folder in DATA_DIR
    existing_pdfs = []
    if os.path.exists(DATA_DIR):
        for root, _, files in os.walk(DATA_DIR):
            if any(
                ignored in root
                for ignored in [
                    ".venv",
                    ".git",
                    "uni-qna",
                    "__pycache__",
                    ".ruff_cache",
                ]
            ):
                continue
            for file in files:
                if file.endswith(".pdf"):
                    existing_pdfs.append(os.path.join(root, file))

    if existing_pdfs:
        selected_paths = st.multiselect(
            "Select notes to index",
            options=existing_pdfs,
            format_func=lambda x: os.path.relpath(x, DATA_DIR),
        )

        if st.button("Index Selected PDFs"):
            for pdf_path in selected_paths:
                # Derive course tag from parent folder name
                course_tag = os.path.basename(os.path.dirname(pdf_path))

                # Index the PDF with course tag
                with st.spinner(f"Indexing {os.path.basename(pdf_path)}..."):
                    result = parse_pdf(pdf_path, course_tag)
                    if result["status"] == "success":
                        st.success(f"✓ Indexed: {result['message']}")
                    elif result["status"] == "skipped":
                        st.info(f"ℹ Skipped: {result['message']}")
                    else:
                        st.error(f"✗ Failed: {result['message']}")

            st.cache_resource.clear()

    else:
        st.info("No PDF files found in the specified directory.")


# -----------------------------------------------------------------------------
# 2. RAG PIPELINE SETUP (Gemma + ChromaDB)
# -----------------------------------------------------------------------------
st.title("📚 University Notes Assistant")


@st.cache_resource
def get_retriever():
    embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-large-en-v1.5")
    vectorstore = Chroma(persist_directory=CHROMA_DIR, embedding_function=embeddings)
    return vectorstore.as_retriever(search_kwargs={"k": 4})


try:
    retriever = get_retriever()
except Exception:
    st.warning(
        "Vector database is empty. Please select and re-index notes in the sidebar."
    )
    st.stop()

# Initialize the LLM (Gemma on Ollama)
llm = ChatOllama(model="gemma2:9b")

# History-Aware Reformulation Prompt
contextualization_q_sys_prompt = (
    "Given a chat history and the latest user question "
    "which might reference context in the chat history "
    "formulate a standalone question which can be understood "
    "without the chat history. Do NOT answer the question, "
    "just reformulate it if needed and otherwise return as it is."
)

contextualize_q_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", contextualization_q_sys_prompt),
        MessagesPlaceholder(variable_name="chat_history"),
        ("human", "{input}"),
    ]
)

history_aware_retriever = create_history_aware_retriever(
    llm, retriever, contextualize_q_prompt
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

answer_prompt = ChatPromptTemplate.from_messages(
    [
        ("system", system_prompt),
        MessagesPlaceholder(variable_name="chat_history"),
        ("human", "{input}"),
    ]
)

question_answer_chain = create_stuff_documents_chain(llm, answer_prompt)
rag_chain = create_retrieval_chain(history_aware_retriever, question_answer_chain)


# -----------------------------------------------------------------------------
# 3. CHAT UI WITH PERSISTENCE
# -----------------------------------------------------------------------------
def log_interaction(query: str, answer: str, sources: list):
    """
    Log chat interactions (query, AI answer, and retrieved sources)
    """
    entry = {
        "timestamp": datetime.now().isoformat(),
        "query": query,
        "answer": answer,
        "sources": [
            {
                "doc_name": doc.metadata.get("doc_name")
                if hasattr(doc, "metadata")
                else doc.get("metadata", {}).get("doc_name"),
                "page_number": doc.metadata.get("page_number")
                if hasattr(doc, "metadata")
                else doc.get("metadata", {}).get("page_number"),
                "image_paths": doc.metadata.get("image_paths")
                if hasattr(doc, "metadata")
                else doc.get("metadata", {}).get("image_paths"),
                "course_name": doc.metadata.get("course_name")
                if hasattr(doc, "metadata")
                else doc.get("metadata", {}).get("course_name"),
            }
            for doc in sources
        ],
    }

    with open(CHAT_LOG_FILE, "a", encoding="utf-8") as f:
        f.write(json.dumps(entry) + "\n")


if "messages" not in st.session_state:
    st.session_state.messages = []

# Display convo history
for message in st.session_state.messages:
    with st.chat_message(message["role"]):
        st.markdown(message["content"])
        if "images" in message:
            for img_path in message["images"]:
                if os.path.exists(img_path):
                    st.image(img_path, caption=os.path.basename(img_path))
        if message.get("sources"):
            with st.expander("🔍 View Retrieved Passages"):
                for i, src in enumerate(message["sources"], start=1):
                    st.markdown(
                        f"**Source {i}: {src.get('course_name', 'Unknown')} / {src.get('doc_name', 'Document')} (Page {src.get('page_number', '?')})**"
                    )
                    st.write(src.get("content", ""))
                    if i < len(message["sources"]):
                        st.divider()

# Process new user input
if user_input := st.chat_input("Ask a question about your notes..."):
    # add user message to chat history and display
    st.session_state.messages.append({"role": "user", "content": user_input})
    with st.chat_message("user"):
        st.markdown(user_input)

    # Format history for langchain
    langchain_history = []
    for msg in st.session_state.messages[:-1]:
        if msg["role"] == "user":
            langchain_history.append(HumanMessage(content=msg["content"]))
        elif msg["role"] == "assistant":
            langchain_history.append(AIMessage(content=msg["content"]))

    with st.spinner("Searching..."):
        response = rag_chain.invoke(
            {"input": user_input, "chat_history": langchain_history}
        )

        answer = response["answer"]
        retrieved_docs = response.get("context", [])

    # Extract image paths from retrieved docs
    doc_image_paths = []
    for doc in retrieved_docs:
        img_list = doc.metadata.get("image_paths", "[]")
        if img_list:
            try:
                paths = json.loads(img_list) if isinstance(img_list, str) else img_list
                for p in paths:
                    if os.path.exists(p) and p not in doc_image_paths:
                        doc_image_paths.append(p)
            except Exception:
                pass

    # Display assistant response with images
    with st.chat_message("assistant"):
        st.markdown(answer)

        # Display image if exists
        for img_path in doc_image_paths:
            if os.path.exists(img_path):
                st.image(img_path, caption=os.path.basename(img_path))

        if retrieved_docs:
            with st.expander("🔍 View Retrieved Passages"):
                for i, doc in enumerate(retrieved_docs, start=1):
                    st.markdown(
                        f"**Source {i}: {doc.metadata.get('course_name', 'Unknown')} / {doc.metadata.get('doc_name', 'Document')} (Page {doc.metadata.get('page_number', '?')})**"
                    )
                    st.write(doc.page_content)
                    if i < len(retrieved_docs):
                        st.divider()

    # Save to session state and append to chat history
    assistant_msg = {
        "role": "assistant",
        "content": answer,
        "sources": [
            {
                "course_name": doc.metadata.get("course_name"),
                "doc_name": doc.metadata.get("doc_name"),
                "page_number": doc.metadata.get("page_number"),
                "content": doc.page_content,
            }
            for doc in retrieved_docs
        ],
    }
    if doc_image_paths:
        assistant_msg["images"] = doc_image_paths

    st.session_state.messages.append(assistant_msg)

    # Log interaction
    log_interaction(user_input, answer, retrieved_docs)
