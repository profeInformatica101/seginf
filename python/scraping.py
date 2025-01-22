import requests
from bs4 import BeautifulSoup

# URL de la página
url = "https://www.paginasamarillas.es/search/informatica/all-ma/all-pr/all-is/sevilla/all-ba/all-pu/all-nc/1"


# Encabezados para simular un navegador real
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Referer": "https://www.google.com/",
    "Connection": "keep-alive"
}
response = requests.get(url, headers=headers)

# Realizar la solicitud GET
#response = requests.get(url)
print(response)
if response.status_code == 200:
    # Parsear el contenido HTML
    soup = BeautifulSoup(response.text, 'html.parser')

    # Buscar los elementos de los negocios
    businesses = soup.find_all("div", class_="listado-item")
    
    for business in businesses:
        # Extraer nombre de la empresa
        name_tag = business.find("h2")
        name = name_tag.text.strip() if name_tag else "No disponible"
        
        # Extraer dirección
        address_tag = business.find("span", itemprop="streetAddress")
        address = address_tag.text.strip() if address_tag else "No disponible"
        
        # Extraer teléfono
        phone_tag = business.find("span", itemprop="telephone")
        phone = phone_tag.text.strip() if phone_tag else "No disponible"
        
        print(f"Nombre: {name}\nDirección: {address}\nTeléfono: {phone}\n{'-'*40}")
else:
    print("Error al acceder a la página")
