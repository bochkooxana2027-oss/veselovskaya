#!/usr/bin/env python3
"""Необязательный шаг: прописать настоящий адрес сайта.

Пока его не выполнить, страница и так работает — все ссылки относительные.
Скрипт добавляет canonical, og:url, JSON-LD url, og:image абсолютным адресом,
sitemap.xml и строку Sitemap в robots.txt. Нужен один раз, после того как
вы узнали адрес репозитория.

    python3 set_url.py https://myuser.github.io/veselovskaya
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(2)
    base = sys.argv[1].rstrip("/")
    if not base.startswith("https://"):
        base = "https://" + base
    print("адрес:", base)

    idx = ROOT / "index.html"
    html = idx.read_text(encoding="utf-8")
    # идемпотентность: сначала вычищаем то, что могли добавить раньше
    html = re.sub(r'\n<link rel="canonical"[^>]*>', "", html)
    html = re.sub(r'\n<meta property="og:url"[^>]*>', "", html)
    html = re.sub(r'\n  "url": "[^"]*",', "", html)
    html = re.sub(r'<meta property="og:image" content="[^"]*">',
                  f'<meta property="og:image" content="{base}/og.png">', html)

    head_add = (f'\n<link rel="canonical" href="{base}/">'
                f'\n<meta property="og:url" content="{base}/">')
    html = html.replace("</head>", head_add + "\n</head>", 1)
    # JSON-LD: url + image всегда абсолютные; правим значение image при повторе
    html = re.sub(r'"image": "[^"]*"',
                  f'"url": "{base}/",\n  "image": "{base}/og.png"', html, count=1)
    idx.write_text(html, encoding="utf-8")

    sitemap = f'''<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url><loc>{base}/</loc><changefreq>weekly</changefreq><priority>1.0</priority></url>
  <url><loc>{base}/files/</loc><changefreq>weekly</changefreq><priority>0.6</priority></url>
</urlset>
'''
    (ROOT / "sitemap.xml").write_text(sitemap, encoding="utf-8")

    rob = ROOT / "robots.txt"
    text = rob.read_text(encoding="utf-8")
    text = re.sub(r"\nSitemap: .*", "", text).rstrip() + f"\n\nSitemap: {base}/sitemap.xml\n"
    rob.write_text(text, encoding="utf-8")

    print("готово: canonical, og:url, sitemap.xml, robots.txt")


if __name__ == "__main__":
    main()
