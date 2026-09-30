# MyCheckList

Aplicativo mobile para criação e gerenciamento de listas e tarefas pessoais.
Projeto de APS — Release 2026-2 — Marco Antônio Gasparotto dos Santos.

Flutter + Dart, arquitetura MVC, autenticação com perfis, Firestore,
SharedPreferences, acelerômetro e vibração.

## Estrutura (MVC — RNF06)

```
lib/
├── main.dart                       Injeção dos controllers + tema
├── firebase_options.dart           Substituir por `flutterfire configure`
├── models/                         MODEL — entidades e serialização
│   ├── usuario.dart
│   ├── lista.dart
│   └── tarefa.dart
├── controllers/                    CONTROLLER — regras e estado
│   ├── auth_controller.dart        UC1, UC2
│   ├── lista_controller.dart       UC3, UC6
│   ├── tarefa_controller.dart      UC4, UC5, UC6, UC8
│   ├── config_controller.dart      UC7
│   └── admin_controller.dart       UC1 (A1)
├── services/                       Infraestrutura (isola o Firebase/SO)
│   ├── firestore_service.dart      RNF04
│   ├── prefs_service.dart          RNF03
│   └── device_service.dart         RNF05
├── views/                          VIEW — telas
│   ├── splash_view.dart
│   ├── login_view.dart
│   ├── cadastro_view.dart
│   ├── home_view.dart
│   ├── tarefas_view.dart
│   ├── config_view.dart
│   └── admin_view.dart
└── widgets/
    ├── lista_card.dart
    └── tarefa_tile.dart
```

As Views nunca conversam com o Firebase: chamam Controllers, que chamam
Services. É o que garante a separação exigida pelo RNF06.

## Como rodar

1. `flutter pub get`
2. Criar um projeto no [Firebase Console](https://console.firebase.google.com)
3. Ativar **Authentication → E-mail/senha** e criar o **Cloud Firestore**
4. `dart pub global activate flutterfire_cli` e depois `flutterfire configure`
   (isso sobrescreve o `lib/firebase_options.dart` de exemplo)
5. Publicar as regras de `firestore.rules` no console
6. `flutter run`

### Criando o Administrador

O cadastro pelo app sempre gera perfil `usuario`. Para ter um administrador,
cadastre uma conta normalmente e, no Firestore Console, altere o campo
`perfil` daquele documento em `usuarios` de `usuario` para `admin`.

## Coleções do Firestore

| Coleção    | Campos |
|------------|--------|
| `usuarios` | nome, email, perfil, ativo, criadoEm |
| `listas`   | usuarioId, nome, descricao, criadaEm, totalTarefas, totalConcluidas |
| `tarefas`  | listaId, usuarioId, descricao, concluida, criadaEm, concluidaEm |

Os campos `totalTarefas` e `totalConcluidas` são agregados recalculados a cada
alteração de tarefa, para que a tela principal mostre o progresso sem precisar
ler todas as tarefas de todas as listas.

## Rastreabilidade dos requisitos

| Requisito | Onde está |
|-----------|-----------|
| UC1 Manter cadastro | `cadastro_view.dart`, `auth_controller.cadastrar`, `admin_view.dart` |
| UC2 Autenticar | `login_view.dart`, `auth_controller.entrar` |
| UC3 Manter listas | `home_view.dart`, `lista_controller.dart` |
| UC4 Manter tarefas | `tarefas_view.dart`, `tarefa_controller.dart` |
| UC5 Concluir tarefa | `tarefa_tile.dart`, `tarefa_controller.alternarConclusao` |
| UC6 Consultar e filtrar | `home_view.dart`, `tarefa_controller.aplicarFiltro` |
| UC7 Configurações | `config_view.dart`, `config_controller.dart`, `prefs_service.dart` |
| UC8 Acelerômetro | `device_service.monitorarAgitacao`, `tarefas_view._aoAgitar` |
| RNF01/RNF02 Perfis | `usuario.dart`, `splash_view.dart` |
| RNF03 Interno | `prefs_service.dart` |
| RNF04 Externo | `firestore_service.dart` |
| RNF05 Sensores | `device_service.dart` |
| RNF06 MVC | estrutura de pastas acima |
| RNF07 Segurança | `firestore.rules`, filtros por `usuarioId` |
| RNF09 Persistência | Firestore + `auth_controller.carregarSessao` |

## Detalhe do UC8

O `DeviceService` monitora o acelerômetro e calcula a magnitude do vetor
(√(x²+y²+z²)). Acima de 22 m/s² conta como agitação, com intervalo mínimo de
2 segundos entre detecções para não disparar em sequência. Ao detectar, o app
vibra, pede confirmação em diálogo e só então limpa o filtro. O diálogo não
aparece quando nenhum filtro está aplicado.
