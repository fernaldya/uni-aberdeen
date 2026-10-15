import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
CHROMA_DIR = os.getenv("CHROMA_DIR", os.path.join(BASE_DIR, "chroma_db"))
MANIFEST_FILE = os.getenv("MANIFEST_FILE", os.path.join(BASE_DIR, "manifest.json"))
