import requests
from bs4 import BeautifulSoup

# URL de la página
url = "https://www.paginasamarillas.es/search/informatica/all-ma/all-pr/all-is/sevilla/all-ba/all-pu/all-nc/1"

# Realizar la solicitud GET
response = requests.get(url)
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
