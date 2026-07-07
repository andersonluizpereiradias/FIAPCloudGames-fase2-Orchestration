# FCG Orchestration (Fase 2)

Repositorio de **orquestracao** da FIAP Cloud Games (Fase 2). Concentra a infraestrutura compartilhada (RabbitMQ + PostgreSQL), o `docker-compose` unificado e os manifestos Kubernetes para subir os 4 microsservicos localmente.

## Arquitetura

4 microsservicos independentes que se comunicam de forma **assincrona via RabbitMQ**:

| Servico | Papel | Banco | REST |
|---|---|:---:|:---:|
| users-api | Cadastro, login (JWT), autorizacao | PostgreSQL | Sim |
| catalog-api | CRUD de jogos, inicia compra, biblioteca | PostgreSQL | Sim |
| payments-api | Simula pagamento (consumidor de eventos) | Nao | So `/health` |
| notifications-api | "Envia" e-mails (log) | PostgreSQL | So `/health` |

Repos dos servicos:
- users-api: https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-UsersAPI
- catalog-api: https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-CatalogAPI
- payments-api: https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-PaymentsAPI
- notifications-api: https://github.com/joao-malvetoni-alta-horizon/FIAPCloudGames-fase2-NotificationsAPI
- contracts: https://github.com/pdelfino0/fcg-contracts

## Estrutura

```
fcg-orchestration/
├── docker-compose.yml   # RabbitMQ + Postgres(3 bancos) + 4 servicos
├── .env.example         # variaveis do Compose (sem valores reais)
├── db/init.sql          # cria catalogdb e notificationsdb
├── k8s/                 # manifestos agregados (kubectl apply -f k8s/)
└── templates/           # modelos de Dockerfile e /k8s por servico
```

## Como rodar com Docker

Pre-requisito: os repos de servico devem estar como **irmaos** deste (`../fcg-users-api`, etc.).

```bash
cp .env.example .env        # ajuste se quiser
docker-compose up --build
docker-compose ps           # todos healthy/running
```

Portas locais: users `8081`, catalog `8082`, payments `8083`, notifications `8084` (interno sempre `8080`).
Painel do RabbitMQ: http://localhost:15672 (fcg/fcg123).

### Testar os fluxos
1. **Cadastro:** `POST http://localhost:8081/api/users/register` -> ver log de boas-vindas no `notifications-api`.
2. **Compra:** iniciar compra no `catalog-api` (8082) -> pagamento aprovado -> jogo na biblioteca -> log de confirmacao.

## Como fazer deploy no Kubernetes (Minikube)

```bash
minikube start

# Build + carga das 4 imagens no cluster local
docker build -t fcg/users-api:1.0 ../fcg-users-api -f ../fcg-users-api/src/FCG.API/Dockerfile
minikube image load fcg/users-api:1.0
docker build -t fcg/catalog-api:1.0 ../fcg-catalog-api -f ../fcg-catalog-api/src/CatalogAPI.API/Dockerfile
minikube image load fcg/catalog-api:1.0
docker build -t fcg/payments-api:1.0 ../fcg-payments-api -f ../fcg-payments-api/src/FCG.API/Dockerfile
minikube image load fcg/payments-api:1.0
docker build -t fcg/notifications-api:1.0 ../fcg-notifications-api -f ../fcg-notifications-api/NotificationsAPI/src/Notifications.API/Dockerfile
minikube image load fcg/notifications-api:1.0

# Aplica tudo (a numeracao garante a ordem)
kubectl apply -f k8s/

# Verifica
kubectl get pods -n fcg
kubectl get deployments,services,configmaps,secrets -n fcg

# Acessar uma API de fora do cluster
kubectl port-forward service/users-api 8081:8080 -n fcg
```

## Variaveis de ambiente por servico

| Variavel | users | catalog | payments | notifications | Origem |
|---|:---:|:---:|:---:|:---:|---|
| `ConnectionStrings__DefaultConnection` | Sim | Sim | — | Sim | Secret |
| `ConnectionStrings__RabbitMqConnection` | — | Sim | — | — | Secret |
| `RabbitMq__Host` | Sim | — | Sim | Sim | ConfigMap |
| `RabbitMq__Password` | Sim | — | Sim | Sim | Secret |
| `JwtSettings__SecretKey` | Sim | Sim | — | — | Secret |
| `ASPNETCORE_ENVIRONMENT` | Sim | Sim | Sim | Sim | ConfigMap |

> **Nota:** o `catalog-api` usa `ConnectionStrings__RabbitMqConnection` (URI `amqp://`) no lugar de `RabbitMq__*`. `users` e `catalog` compartilham a mesma `JwtSettings__SecretKey`. `payments` nao tem banco nem JWT.

> **Secret** e apenas base64 (nao e cofre). Nao comite valores reais.
