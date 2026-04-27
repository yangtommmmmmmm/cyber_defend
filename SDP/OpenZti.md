1.Setup OpenZti on Controller:

Step1.New-Item -ItemType Directory -Path 'C:\ziti' -Force

Step2.Set-Location 'C:\ziti'--->cd:\ziti

Step3.As below:

<img width="975" height="153" alt="image" src="https://github.com/user-attachments/assets/774463da-d030-4ecc-b717-cc0eb4607b3c" />

Step4.Trigger the Quickstart to setup 'Controller' and 'Router':

<img width="482" height="38" alt="image" src="https://github.com/user-attachments/assets/3d7f3a2a-8ba0-4c73-8d02-35c8dc6f833b" />

<img width="975" height="255" alt="image" src="https://github.com/user-attachments/assets/e85fed44-d533-44ea-89d1-206ee32308a4" />

Step5.Login to Controller with admin/admin:

ziti edge login https://localhost:1280 --username admin --password admin --yes


2.Setup Identities:

Step1.Setup IH to generate IH-JWT:

<img width="975" height="36" alt="image" src="https://github.com/user-attachments/assets/c2acffd3-cb50-4362-b241-390978bf5a6a" />

Step2.Setup AH1 to generate AH1-JWT:

<img width="975" height="24" alt="image" src="https://github.com/user-attachments/assets/549e623f-200c-48e1-a498-22de9933b404" />

Step3.Setup AH2 to generate AH2-JWT:

<img width="975" height="23" alt="image" src="https://github.com/user-attachments/assets/53a0e07e-70f2-42f0-ba5c-0fff2208dc45" />

3.Setup Services:

Step1.Web Services for AH1:

Step1-1.Create Web Service:

<img width="975" height="26" alt="image" src="https://github.com/user-attachments/assets/44f2cf89-c145-4f2e-bb4e-2328ac4fd0c2" />

Step1-2.Combined Web Service to AH1:

<img width="975" height="34" alt="image" src="https://github.com/user-attachments/assets/54de980e-10a1-4c50-9b46-226be53cfdbb" />

Step2.SSH Service for AH2:

Step2-1.Create SSH Service:

<img width="975" height="23" alt="image" src="https://github.com/user-attachments/assets/be14f7f1-b4ab-48b1-b13b-c397fd6782a6" />

Step2-2.Combined SSH Service to AH2:

<img width="975" height="35" alt="image" src="https://github.com/user-attachments/assets/3cbffc23-e10c-436a-bc5f-2eb149e1c13e" />

Step3.Set IH only access to AH1-Web Service:

<img width="975" height="39" alt="image" src="https://github.com/user-attachments/assets/acd1b3fb-f6f0-49d7-ae49-1994d8fade43" />

Step4.Generate the setting config in json format for interception:

Step4-1.For AH1-Web:

<img width="975" height="38" alt="image" src="https://github.com/user-attachments/assets/d8893a0b-2e62-4f6f-8e0a-7678aeff3e2f" />

<img width="975" height="40" alt="image" src="https://github.com/user-attachments/assets/b65b667e-5926-4e93-84af-e2fff6dcb7c5" />

Step4-2.For AH2-SSH:

<img width="975" height="39" alt="image" src="https://github.com/user-attachments/assets/98278859-43f2-4421-928e-069fe92f5c05" />

<img width="975" height="43" alt="image" src="https://github.com/user-attachments/assets/cdf93ceb-740c-4302-87b1-576b292e94fc" />

Step5.Apply setting config with json format for interception to service config:

<img width="975" height="179" alt="image" src="https://github.com/user-attachments/assets/d9c6e231-87db-4db8-a8e0-418bea02c6cc" />

4.Setup Router-Policy:

<img width="975" height="37" alt="image" src="https://github.com/user-attachments/assets/78f09438-9d20-4623-96e0-e08256e69215" />

<img width="975" height="35" alt="image" src="https://github.com/user-attachments/assets/78c705e8-ce1a-4964-90df-e3fe2b2b3321" />

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

5.Setup SDP Agent on IH/AH1/AH2:

Step1.Download ziti-edge-tunnel on IH/AH1/AH2:

<img width="975" height="95" alt="image" src="https://github.com/user-attachments/assets/5f180386-ca24-462b-a53e-57dad1f528f7" />

Step2.Transfer JWT located on controller to IH/AH1/AH2 by any ways. In Fortinet,transfer it by username/password.

Step3.Do enrolling on IH/AH1/AH2:

Step3-1.IH:

<img width="975" height="32" alt="image" src="https://github.com/user-attachments/assets/eb11ba36-2d48-4ff2-adee-2c5aea6f97d3" />

Step3-2.AH1:

<img width="975" height="25" alt="image" src="https://github.com/user-attachments/assets/36e1b16f-7292-44fb-84c7-fbf388183125" />

Step3-3.AH2:

<img width="975" height="25" alt="image" src="https://github.com/user-attachments/assets/371ede76-3bfb-4bdb-b780-6ca4bf0e7442" />

Step4.Trigger the agent:

Step4-1.IH:

<img width="975" height="102" alt="image" src="https://github.com/user-attachments/assets/699b621b-606c-41b1-ab51-fc719828564e" />

Step4-2.AH1:

<img width="975" height="159" alt="image" src="https://github.com/user-attachments/assets/9462621e-3891-46a7-96e0-752a04f2732a" />

Step4-3.AH2:

<img width="975" height="101" alt="image" src="https://github.com/user-attachments/assets/fc289555-50b4-4484-99ad-fc24c69b6e83" />

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

Checking1:

<img width="975" height="436" alt="image" src="https://github.com/user-attachments/assets/324b1419-5f9c-4413-9c73-bb747ca3517d" />

Checking2:

<img width="975" height="280" alt="image" src="https://github.com/user-attachments/assets/12640c68-b7f0-4566-b6fc-898f63b1c24d" />
