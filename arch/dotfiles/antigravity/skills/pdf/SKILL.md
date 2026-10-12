---
name: pdf
description: Use this skill whenever the user wants to do anything with PDF files. This includes reading or extracting text/tables from PDFs, combining or merging multiple PDFs into one, splitting PDFs apart, rotating pages, adding watermarks, creating new PDFs, filling PDF forms, encrypting/decrypting PDFs, extracting images, and OCR on scanned PDFs to make them searchable.
---

# PDF Processing & Manipulation Skill

A comprehensive runbook for manipulating, extracting, and generating PDF documents programmatically using Python libraries and CLI utilities.

---

## 1. Quick Tool Selection Matrix

| Operation | Preferred Tool / Library | Command / Method |
| :--- | :--- | :--- |
| **Extract Text & Simple Inspection** | `pypdf` | `reader.pages[i].extract_text()` |
| **Extract Structured Tables** | `pdfplumber` | `page.extract_tables()` / `extract_words()` |
| **High Performance & Image Extraction** | `pymupdf` (`fitz`) | `doc.load_page(i).get_pixmap()` |
| **Merging, Splitting, Rotating** | `pypdf` | `PdfWriter()` / `add_page()` |
| **Creating PDFs from Scratch** | `reportlab` or `weasyprint` | Programmatic canvas or HTML-to-PDF |
| **Scanned Document OCR** | `pdf2image` + `pytesseract` | Image conversion + Tesseract engine |

---

## 2. Core Python Recipes

### A. Extracting Text with Layout Preservation (`pdfplumber`)
```python
import pdfplumber

def extract_text_and_tables(pdf_path: str):
    with pdfplumber.open(pdf_path) as pdf:
        for index, page in enumerate(pdf.pages):
            print(f"--- Page {index + 1} ---")
            text = page.extract_text(layout=True)
            print(text)

            tables = page.extract_tables()
            for t_idx, table in enumerate(tables):
                print(f"Table {t_idx + 1}:")
                for row in table:
                    print(row)
```

### B. Merging Multiple PDFs (`pypdf`)
```python
from pypdf import PdfWriter, PdfReader
from typing import List

def merge_pdfs(input_paths: List[str], output_path: str):
    writer = PdfWriter()
    for path in input_paths:
        reader = PdfReader(path)
        for page in reader.pages:
            writer.add_page(page)
    with open(output_path, "wb") as f:
        writer.write(f)
    print(f"Successfully merged {len(input_paths)} files into {output_path}")
```

### C. Splitting & Rotating Pages (`pypdf`)
```python
from pypdf import PdfReader, PdfWriter

def split_and_rotate(input_pdf: str, page_num: int, rotation_deg: int, output_pdf: str):
    reader = PdfReader(input_pdf)
    writer = PdfWriter()
    page = reader.pages[page_num]
    page.rotate(rotation_deg)  # 90, 180, or 270 degrees
    writer.add_page(page)
    with open(output_pdf, "wb") as f:
        writer.write(f)
```

### D. Extracting Embedded Images (`pymupdf` / `fitz`)
```python
import fitz # PyMuPDF
import io
from PIL import Image

def extract_images(pdf_path: str, output_dir: str = "."):
    doc = fitz.open(pdf_path)
    for page_idx in range(len(doc)):
        for img_idx, img in enumerate(doc[page_idx].get_images()):
            xref = img[0]
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            image_ext = base_image["ext"]
            image = Image.open(io.BytesIO(image_bytes))
            image.save(f"{output_dir}/page_{page_idx+1}_img_{img_idx+1}.{image_ext}")
```

### E. Generating PDFs from HTML / CSS (`weasyprint` or `reportlab`)
```python
# HTML to high-quality PDF
from weasyprint import HTML, CSS

def render_html_to_pdf(html_content: str, output_pdf: str, css_styles: str = None):
    css = [CSS(string=css_styles)] if css_styles else []
    HTML(string=html_content).write_pdf(output_pdf, stylesheets=css)
```

---

## 3. Best Practices

1. **Memory Safety with Large Documents**:
   - For PDFs with hundreds of pages, avoid reading all pages into memory at once. Stream or iterate page-by-page using generator expressions.
2. **Encrypted Documents**:
   - Check `reader.is_encrypted` before processing. Attempt decryption with `reader.decrypt(password)` when protected.
3. **Validating Output**:
   - Always verify the generated PDF file size and page count to ensure write completeness.
