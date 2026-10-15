import os
import hashlib
import json
import pymupdf
from langchain_core.documents import Document
from langchain_huggingface import HuggingFaceEmbeddings
from langchain_chroma import Chroma
from langchain_text_splitters import RecursiveCharacterTextSplitter

# pyrefly: ignore[missing-import]
from __init__ import CHROMA_DIR, MANIFEST_FILE


def calculate_file_hash(file_path: str) -> str:
    hasher = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(8192):
            hasher.update(chunk)
    return hasher.hexdigest()


def load_manifest() -> dict:
    """Load JSON manifest to track file hashes."""
    if not os.path.exists(MANIFEST_FILE):
        return {}
    try:
        with open(MANIFEST_FILE, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return {}


def save_manifest(manifest: dict):
    """Save updated file hashes to the JSON manifest."""
    with open(MANIFEST_FILE, "w", encoding="utf-8") as f:
        json.dump(manifest, f, indent=2)


def extract_page_images_by_label(page_text: str, course_img_dir: str) -> list[str]:
    r"""
    Scans extracted page text for \label{fig:<image_name>} or fig:<image_name> references
    and matches them to image files inside the course's images/ directory.
    """
    matched_images = []
    if not os.path.exists(course_img_dir):
        return matched_images

    # Fetch list of available images
    available_images = set(os.listdir(course_img_dir))
    page_text_lower = page_text.lower()

    for img_file in available_images:
        # Remove extension
        stem = os.path.splitext(img_file)[0]
        stem_lower = stem.lower()

        # Check for \label{fig:<name>} or fig:<name>
        if f"fig:{stem_lower}" in page_text_lower:
            img_path = os.path.join(course_img_dir, img_file)
            if img_path not in matched_images:
                matched_images.append(img_path)

    return matched_images


def parse_pdf(
    file_path: str,
    course_name: str,
) -> dict:
    """
    Parse a PDF file and store it in a vector database.
    If it already exists then purge it first (if hash changes)
    before storing it and updating the hash.

    Args:
        file_path (str): Path to the PDF file.
        course_name (str): Name of the course.

    Returns:
        dict: Status of the operation.
    """
    if not os.path.exists(file_path):
        return {"status": "error", "message": f"File not found: {file_path}"}

    doc_name = os.path.basename(file_path)
    manifest = load_manifest()
    current_hash = calculate_file_hash(file_path)

    # Skip processing if the file hash has not changed since the last run
    if manifest.get(file_path) == current_hash:
        return {
            "status": "skipped",
            "message": "File already processed and has no changes from previous load.",
        }

    # Derive course directory and path to images
    course_dir = os.path.dirname(file_path)
    img_dir = os.path.join(course_dir, "images")

    # Initialize model & DB vectorstore
    embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-large-en-v1.5")
    vectorstore = Chroma(embedding_function=embeddings, persist_directory=CHROMA_DIR)

    # 1. Purge existing vectors for this doc
    try:
        vectorstore.delete(where={"doc_name": doc_name})
    except Exception as e:
        return {
            "status": "error",
            "message": f"Failed to delete existing vectors: {str(e)}",
        }

    # 2. Parse PDF and attach Metadata to each page
    doc_pdf = pymupdf.open(file_path)
    raw_documents = []

    for page_idx in range(len(doc_pdf)):
        page_text = doc_pdf[page_idx].get_text()

        # Match fig labels against images in local course image/ dir
        page_image_paths = extract_page_images_by_label(page_text, img_dir)

        # Store image paths as a JSON (or empty if no images found)
        metadata = {
            "course_name": course_name,
            "doc_name": doc_name,
            "page_number": page_idx + 1,
            "image_paths": json.dumps(page_image_paths) if page_image_paths else "[]",
        }

        raw_documents.append(Document(page_content=page_text, metadata=metadata))

    doc_pdf.close()

    # 3. Chunk & Assign Deterministic IDs
    text_splitter = RecursiveCharacterTextSplitter(
        chunk_size=900, chunk_overlap=150, separators=["\n\n", "\n", " ", ""]
    )
    chunks = text_splitter.split_documents(raw_documents)
    chunk_ids = [f"{doc_name}#chunk_{idx}" for idx in range(len(chunks))]

    # 4. Re-Insert Fresh Chunks
    if chunks:
        vectorstore.add_documents(documents=chunks, ids=chunk_ids)

    # 5. Update Manifest
    manifest[file_path] = current_hash
    save_manifest(manifest)

    return {
        "status": "success",
        "message": f"Indexed: {doc_name} ({len(chunks)} chunks)",
    }


def purge_file(file_path: str) -> dict:
    """
    Purge all chunks for a document from Chroma vector database and remove from manifest.

    Args:
        file_path (str): Key or path of the document as stored in manifest.

    Returns:
        dict: Status of the purge operation.
    """
    doc_name = os.path.basename(file_path)
    manifest = load_manifest()

    embeddings = HuggingFaceEmbeddings(model_name="BAAI/bge-large-en-v1.5")
    vectorstore = Chroma(embedding_function=embeddings, persist_directory=CHROMA_DIR)

    try:
        vectorstore.delete(where={"doc_name": doc_name})
    except Exception as e:
        return {
            "status": "error",
            "message": f"Failed to delete vectors for {doc_name}: {str(e)}",
        }

    # Remove from manifest
    found = False
    if file_path in manifest:
        del manifest[file_path]
        found = True
    else:
        for key in list(manifest.keys()):
            if os.path.basename(key) == doc_name:
                del manifest[key]
                found = True

    if found:
        save_manifest(manifest)

    return {"status": "success", "message": f"Purged: {doc_name}"}
