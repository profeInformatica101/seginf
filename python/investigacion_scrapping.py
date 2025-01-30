from bs4 import BeautifulSoup
import requests

# URL de la página
url = "https://www.diariosur.es/malaga-capital/educacion-corte-ingles-firman-convenio-impulsar-dual-20250129164427-nt.html"

# Descargar el HTML
headers = {"User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64)"}
response = requests.get(url, headers=headers)
html = response.text

# Parsear el HTML con BeautifulSoup
soup = BeautifulSoup(html, "lxml")

# Extraer los elementos con la clase "v-p"
elements = soup.find_all(class_="v-p")

# Guardar los textos extraídos
for i, element in enumerate(elements, start=1):
    print(f"Texto {i}: {element.get_text(strip=True)}")
