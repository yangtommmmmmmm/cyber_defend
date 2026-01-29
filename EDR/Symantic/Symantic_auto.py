import os
import time
import requests
from selenium import webdriver
from selenium.webdriver.edge.service import Service as EdgeService
from selenium.webdriver.edge.options import Options
from selenium.webdriver.common.by import By

# Downloading URL
url = "https://www.broadcom.com/support/security-center/definitions/download/detail?gid=sep14"

# Saved Directory
output_dir = r"C:\Users\User\Desktop\test"
os.makedirs(output_dir, exist_ok=True)

# Edge Driver Directory（C:\WebDriver\msedgedriver）
edge_driver_path = r"C:\WebDriver\msedgedriver.exe"

# Edge options
options = Options()
options.add_argument("--headless")  # Headless mode
options.add_argument("--disable-gpu")

# Trigger the browser
service = EdgeService(edge_driver_path)
driver = webdriver.Edge(service=service, options=options)

try:
    print(f"Open {url} ...")
    driver.get(url)

    # Waiting for downloading link by Javascript
    time.sleep(10)  # Also 'WebDriveWait'

    # Find all links with '.jdb'
    links = driver.find_elements(By.CSS_SELECTOR, "a[href$='core3sdsi64.jdb']")

    if not links:
        print("Can't find links with .jdb")
    else:
        for link in links:
            file_url = link.get_attribute("href")
            file_name = os.path.basename(file_url)
            out_path = os.path.join(output_dir, file_name)

            if os.path.exists(out_path):
                print(f"{file_name} has existed,bypass")
                continue

            print(f"Downloading {file_name} ...")
            try:
                # Block downloading in stream mode
                with requests.get(file_url, stream=True, timeout=60) as r:
                    r.raise_for_status()  # If http error,go exception
                    with open(out_path, "wb") as f:
                        for chunk in r.iter_content(chunk_size=8192):
                            if chunk:
                                f.write(chunk)
            except requests.exceptions.RequestException:
                # 完全忽略下載錯誤（可選：印出提示）
                print(f"{file_name} downloading failure,bypass")

        print("Downloading finish！")

finally:
    driver.quit()
