# Como Adicionar um Novo Tenant (Flavor)

Este guia é um passo a passo objetivo para adicionar um novo tenant ao projeto, garantindo que ele tenha sua própria identidade (ID, nome, ícone), configuração e assinatura digital para as lojas.

Usaremos os seguintes placeholders:
* `<novo_tenant>`: O nome do novo flavor em minúsculas (ex: `aracruz`).
* `<NomeDoApp>`: O nome de exibição do aplicativo (ex: `Aracruz App`).
* `<com.empresa.novoapp>`: O ID único do aplicativo para a loja (ex: `com.aracruz.app`).

### Pré-requisitos
* Acesso ao `keytool` (parte do Java Development Kit).
* Acesso a um ambiente macOS com Xcode para a configuração do iOS.

## Passo 1: Configuração da Assinatura Digital (Android)

Cada app precisa de uma chave única para a Google Play.

1.  **Gerar Keystore:** No terminal, gere o arquivo de chave para o novo tenant.
    ```bash
    keytool -genkey -v -keystore <novo_tenant>-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <novo_tenant>-alias
    ```

2.  **Mover Arquivo:** Mova o arquivo `<novo_tenant>-release-key.jks` gerado para a pasta `android/keystores/`.

3.  **Criar Propriedades:** Crie o arquivo `android/keystores/<novo_tenant>.properties`. Preencha com as senhas e informações da chave gerada.
    ```properties
    # android/keystores/<novo_tenant>.properties
    storePassword=[SENHA_DO_KEYSTORE]
    keyPassword=[SENHA_DA_CHAVE]
    keyAlias=<novo_tenant>-alias
    storeFile=<novo_tenant>-release-key.jks
    ```

## Passo 2: Configuração do Projeto Android

1.  **Configurar `build.gradle.kts`:** Abra o arquivo `android/app/build.gradle.kts`.
    * **Adicionar Flavor:** Dentro do bloco `productFlavors`, adicione o novo tenant.
        ```kotlin
        // ...
        create("guarappari") { /* ... */ }
        create("belluga") { /* ... */ }
        
        // Adicione este bloco para o novo tenant
        create("<novo_tenant>") {
            dimension = "tenant"
            applicationId = "<com.empresa.novoapp>"
        }
        // ...
        ```
    * **Configurar Assinatura (IMPORTANTE):** Se esta é a primeira vez configurando um flavor de release, substitua o bloco `buildTypes` e adicione a lógica de `signingConfigs` para habilitar a assinatura correta.
        ```kotlin
        // No topo do arquivo, depois de 'plugins { ... }'
        val keyProperties = java.util.Properties()

        android {
            // ...
            
            // Adicione este bloco se não existir
            signingConfigs {
            }

            buildTypes {
                getByName("release") {
                    // Garante que a assinatura seja definida por flavor
                    signingConfig = signingConfigs.findByName(name)
                }
            }
            
            flavorDimensions.add("tenant")

            productFlavors {
                // Itera sobre cada flavor para configurar a assinatura dinamicamente
                forEach { flavor ->
                    val flavorPropertiesFile = rootProject.file("keystores/${flavor.name}.properties")
                    if (flavorPropertiesFile.exists()) {
                        keyProperties.load(java.io.FileInputStream(flavorPropertiesFile))
                        signingConfigs.create(flavor.name) {
                            keyAlias = keyProperties["keyAlias"] as String
                            keyPassword = keyProperties["keyPassword"] as String
                            storePassword = keyProperties["storePassword"] as String
                            storeFile = file("../keystores/${keyProperties["storeFile"]}")
                        }
                        flavor.signingConfig = signingConfigs.getByName(flavor.name)
                    }
                }
                
                // Definições dos seus flavors
                create("guarappari") { /* ... */ }
                create("belluga") { /* ... */ }
                create("<novo_tenant>") {
                    dimension = "tenant"
                    applicationId = "<com.empresa.novoapp>"
                }
            }
        }
        ```

2.  **Definir Nome do App:**
    * Crie a pasta: `android/app/src/<novo_tenant>/res/values/`.
    * Crie o arquivo `strings.xml` dentro dela com o conteúdo:
        ```xml
        <?xml version="1.0" encoding="utf-8"?>
        <resources>
            <string name="app_name"> <NomeDoApp> </string>
        </resources>
        ```

3.  **Definir Ícone do App:**
    * Crie a estrutura de pastas: `android/app/src/<novo_tenant>/res/`.
    * Dentro dela, crie as pastas `mipmap-hdpi`, `mipmap-mdpi`, etc., e coloque os arquivos `ic_launcher.png` correspondentes.

## Passo 3: Configuração do Projeto iOS (Xcode)

Abra o projeto `ios/Runner.workspace` no Xcode e siga os passos:

1.  **Duplicar Configurações de Build:**
    * Selecione o projeto `Runner` > aba **Info** > **Configurations**.
    * Clique no `+` e duplique as configurações `Debug` e `Release`, nomeando-as `Debug-<novo_tenant>` e `Release-<novo_tenant>`.

2.  **Criar Novo "Scheme":**
    * No menu de schemes (topo da janela), selecione **New Scheme...**.
    * Nomeie o novo scheme como `<novo_tenant>`.

3.  **Configurar o Scheme:**
    * No menu de schemes, selecione **Edit Scheme...**.
    * Para as ações `Run`, `Test`, `Profile`, `Analyze`, e `Archive`, ajuste o **Build Configuration** para usar as novas configurações (`Debug-<novo_tenant>` ou `Release-<novo_tenant>`).

4.  **Definir Identidade do App:**
    * Selecione o **TARGET** `Runner` > aba **Build Settings**.
    * Procure e defina o valor de **Product Bundle Identifier** para `<com.empresa.novoapp>` nas configurações do `<novo_tenant>`.
    * Procure e defina o valor da configuração **APP_DISPLAY_NAME** para `<NomeDoApp>` nas configurações do `<novo_tenant>`.

5.  **Definir Assinatura Apple:**
    * Vá para a aba **Signing & Capabilities**.
    * Para as configurações `Debug-<novo_tenant>` e `Release-<novo_tenant>`, selecione o **Team** de desenvolvimento Apple correto (geralmente o do cliente).

## Passo 4: Configuração do Código Dart

1.  **Abra o `TenantRepository.dart`**:
    * Localize o método `init()`. Este método é o responsável por carregar as informações do tenant com base no flavor que está rodando (lendo a variável de ambiente `FLAVOR`).
    * Adicione a lógica necessária para reconhecer o `"<novo_tenant>"` e carregar os dados corretos para ele (seja de um mapa local, de uma API, etc.).

## Passo 5: Configuração do VS Code

1.  **Abra `.vscode/launch.json`:**
2.  Adicione um novo objeto de configuração para o novo tenant, copiando e editando um existente:
    ```json
    {
        "name": "<NomeDoApp> (Debug)",
        "request": "launch",
        "type": "dart",
        "flutterMode": "debug",
        "args": [
            "--flavor",
            "<novo_tenant>",
            "--dart-define=FLAVOR=<novo_tenant>"
        ]
    }
    ```

## Passo 6: Verificação Final

Após completar os passos, faça uma limpeza e execute o novo flavor para testar.

1.  **Limpe o projeto:**
    ```bash
    fvm flutter clean
    ```
2.  **Execute via terminal:**
    ```bash
    fvm flutter run --flavor <novo_tenant> --dart-define=FLAVOR=<novo_tenant>
    ```
3.  **Execute via VS Code:**
    * Vá para a aba "Run and Debug" (🐞).
    * Selecione a nova configuração (`<NomeDoApp> (Debug)`) no menu dropdown.
    * Clique no botão de "play".

## Defines por Ambiente (Compile Time)

Este projeto usa `--dart-define-from-file` para definir ambiente em tempo de compilação (não em runtime).

Arquivos versionados:
- `config/defines/dev.json`
- `config/defines/stage.json`
- `config/defines/main.json`

Override local (não versionado):
- `config/defines/local.override.json` (baseado em `config/defines/local.override.example.json`)

Regras importantes:
- `LANDLORD_DOMAIN` deve ser uma origem completa (`http://` ou `https://`), sem path/query.
- Em ambiente local com tenant por subdomínio, não use host IP puro (`http://192.168.x.x:8081`), pois subdomínios não resolvem. Use um host wildcard DNS, por exemplo `http://192.168.0.10.nip.io:8081`.

Execução local recomendada (lane `dev` + override local opcional):

```bash
./tool/with_lane_defines.sh dev run --flavor <novo_tenant>
```

Sem helper script:

```bash
fvm flutter run --flavor <novo_tenant> \
  --dart-define-from-file=config/defines/dev.json \
  --dart-define-from-file=config/defines/local.override.json
```

Nota de operação CI/CD: este commit inclui um ajuste documental mínimo para disparar a simulação ponta a ponta do fluxo de promoção de lanes.

Nota de simulação CI/CD (flutter): alteração documental mínima para validar o fluxo integrado com backend no mesmo ciclo.
