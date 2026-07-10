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

Contrato Android aprovado para este repositório:
- Arquivo público versionado: `android/flavors/<flavor>.public.properties`
- Arquivo secreto ignorado: `android/keystores/<flavor>.signing.properties`
- Keystore fixo ignorado: `android/keystores/<flavor>.jks`
- The build must fail closed if the public file is missing, if required public properties are missing, or if the required secret signing file is absent.

1.  **Gerar Keystore:** No terminal, gere o arquivo de chave para o novo tenant.
    ```bash
    keytool -genkey -v -keystore <novo_tenant>.jks -keyalg RSA -keysize 2048 -validity 10000 -alias <novo_tenant>-alias
    ```

2.  **Mover Arquivo:** Mova o arquivo `<novo_tenant>.jks` gerado para `android/keystores/<novo_tenant>.jks`.

3.  **Criar Configuração Pública:** Crie o arquivo versionado `android/flavors/<novo_tenant>.public.properties` com os dados não secretos do flavor.
    ```properties
    # android/flavors/<novo_tenant>.public.properties
    applicationId=<com.empresa.novoapp>
    appLinkHosts=tenant.example.com,tenant-app.example.com
    ```
    * Para referência/base de novos tenants, use o template genérico `android/flavors/tenant.public.properties.example`.

4.  **Criar Configuração Secreta:** Crie o arquivo ignorado `android/keystores/<novo_tenant>.signing.properties` com os segredos de assinatura.
    ```properties
    # android/keystores/<novo_tenant>.signing.properties
    storePassword=[SENHA_DO_KEYSTORE]
    keyPassword=[SENHA_DA_CHAVE]
    keyAlias=<novo_tenant>-alias
    ```
    * Para referência/base, use o template genérico `android/keystores/tenant.signing.properties.example`.

5.  **Validação esperada:** Não mova `applicationId` ou `appLinkHosts` para segredos/variáveis opacas de CI. The build must fail closed when `android/flavors/<flavor>.public.properties` is missing, when `applicationId` or `appLinkHosts` is missing from that public file, or when `android/keystores/<flavor>.signing.properties` is missing.

## Passo 2: Configuração do Projeto Android

1.  **Configurar `build.gradle.kts`:** Abra o arquivo `android/app/build.gradle.kts`.
    * **Adicionar Flavor:** O Gradle descobre cada flavor Android a partir dos arquivos `android/flavors/*.public.properties`. Não adicione blocos manuais `create("<novo_tenant>")` no `productFlavors`; o nome do novo flavor nasce do arquivo `android/flavors/<novo_tenant>.public.properties` e da pasta Android correspondente em `android/app/src/<novo_tenant>/`.
    * **Configurar Assinatura (IMPORTANTE):** Mantenha o Gradle alinhado ao contrato de dois arquivos. Os dados públicos do flavor devem vir de `android/flavors/<novo_tenant>.public.properties`, enquanto os segredos devem vir de `android/keystores/<novo_tenant>.signing.properties`, usando `android/keystores/<novo_tenant>.jks` como caminho fixo do keystore. The build must fail closed if the public file is missing, if `applicationId` or `appLinkHosts` is missing from that file, or if the required secret signing file is absent.
        ```kotlin
        android {
            // ...

            productFlavors {
                // Os flavors são descobertos a partir de android/flavors/*.public.properties
                // e das pastas android/app/src/<flavor>/.
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

4.  **Executar a verificação do contrato Android:**
    * Rode `./tool/verify_android_flavor_contract.sh --flavor <novo_tenant>` para validar:
      * os arquivos públicos versionados do flavor;
      * os arquivos secretos ignorados;
      * as falhas fechadas para arquivo público ausente, propriedades públicas ausentes, signing file ausente e keystore ausente.

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
- `config/defines/dev.example.json`
- `config/defines/stage.example.json`
- `config/defines/main.example.json`

Override local (não versionado):
- `config/defines/local.override.json` (baseado em `config/defines/local.override.example.json`)
- O override local só deve ser aplicado na lane `dev`. Ele não deve contaminar builds `stage`/`main`.

Regras importantes:
- `LANDLORD_DOMAIN` deve ser uma origem completa (`http://` ou `https://`), sem path/query.
- Em ambiente local com tenant por subdomínio, não use host IP puro (`http://192.168.x.x:8081`), pois subdomínios não resolvem. Use um host wildcard DNS, por exemplo `http://192.168.0.10.nip.io:8081`.
- Em fluxo web/browser, `LANDLORD_DOMAIN` deve refletir a origem que o navegador realmente abre. Se o acesso local estiver passando por hosts públicos/tunelados do projeto, mantenha essas URLs apenas nos arquivos concretos do downstream (`*.json` reais ou `local.override.json`), não nos `.example`.
- Os arquivos `*.example.json` existem para Boilerplate/downstreams novos: preservam a estrutura e podem carregar notas de referência, mas não devem servir defaults ativos do projeto atual.

Execução local recomendada (override local, desenvolvimento):

```bash
fvm flutter run --flavor <novo_tenant> \
  --dart-define-from-file=config/defines/local.override.json
```

Build local com helper Delphi:

```bash
./script/build_lane.sh dev apk --debug --flavor <novo_tenant>
```

Build local com lane derivada da branch atual:

```bash
./script/build_lane.sh apk --debug --flavor <novo_tenant>
./script/build_lane.sh appbundle --release --flavor <novo_tenant>
```

Run local com helper Delphi (workspace com `delphi-ai` atualizado):

```bash
./script/run_lane.sh --flavor <novo_tenant>
./script/run_lane.sh stage --debug --flavor <novo_tenant>
./script/run_lane.sh main --release --flavor <novo_tenant> -d <device-id>
```

Regra do helper:
- branch `main` -> `config/defines/main.json`
- branch `stage` -> `config/defines/stage.json`
- qualquer outra branch (`dev`, feature, orchestration, etc.) -> `config/defines/dev.json`
- `config/defines/local.override.json` só é aplicado quando a lane resolvida é `dev`
- o helper valida a origem efetiva (`BOOTSTRAP_BASE_URL` ou `LANDLORD_DOMAIN`) antes do build
- o helper valida a existência do artifact gerado ao final do build (`apk`, `appbundle`, `web`)
- `./script/run_lane.sh` usa o mesmo resolver de lane/defines e delega a seleção de device ao `flutter run`

Execução de integração (WSL + device), com define tenant por padrão:

```bash
./tool/run_integration_test_wsl.sh integration_test/feature_shell_navigation_smoke_test.dart
```

Notas:
- O script usa `config/defines/integration.tenant.json` por padrão para evitar rodar integração em domínio landlord raiz.
- Overrides opcionais por ambiente:
  - `ADB_DEVICE=<ip:porta>`
  - `FLUTTER_INTEGRATION_FLAVOR=<flavor>`
  - `INTEGRATION_DEFINE_FILE=<arquivo-json>`

Nota de operação CI/CD: este commit inclui um ajuste documental mínimo para disparar a simulação ponta a ponta do fluxo de promoção de lanes.

Nota de simulação CI/CD (flutter): alteração documental mínima para validar o fluxo integrado com backend no mesmo ciclo.
