import requests
from bs4 import BeautifulSoup

# Lista de ciudades
ciudades = ["camas", "sevilla", "santiponce", "tomares"]

# URL base
base_url = "https://www.paginasamarillas.es/search/informatica/all-ma/all-pr/all-is/{}/all-ba/all-pu/all-nc/1"

# Encabezados para simular un navegador real
headers = {
    "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36",
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Accept-Language": "en-US,en;q=0.5",
    "Referer": "https://www.google.com/",
    "Connection": "keep-alive"
}

# Diccionario para almacenar resultados únicos
businesses_data = {}

for ciudad in ciudades:
    print(f"\nRecuperando datos de la ciudad: {ciudad.capitalize()}\n{'-'*50}")
    
    # Construir la URL para la ciudad
    url = base_url.format(ciudad)
    
    # Realizar la solicitud GET
    response = requests.get(url, headers=headers)
    
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

            # Crear un identificador único para evitar duplicados
            unique_key = f"{name}-{address}-{phone}"

            if unique_key not in businesses_data:
                businesses_data[unique_key] = {
                    "Nombre": name,
                    "Dirección": address,
                    "Teléfono": phone,
                    "Ciudad": ciudad.capitalize()
                }
    else:
        print(f"Error al acceder a los datos de la ciudad: {ciudad.capitalize()}\n")

# Imprimir resultados únicos
print("\nListado final de negocios únicos:\n")
total = 0
for business in businesses_data.values():
    total += 1
    print(f"{total} .- Nombre: {business['Nombre']}\nDirección: {business['Dirección']}\nTeléfono: {business['Teléfono']}\nCiudad: {business['Ciudad']}\n{'-'*40}")

print(f"\nTotal de negocios únicos encontrados: {total}")
