# dev_utils

## How to Run setup all services
This script assumes you are cloning all the required repos creators-studio, creators-studio-api, db-migrations, kafka-consumer in the $COFFEEZ_ROOT directory configured in .env file

Update .env
```
KAFKA_INSTALL_PATH=/opt/kafka
COFFEEZ_ROOT=/Users/someuser/Go/src/github.com/coffeezHQ
```

Make it executable:

```bash
chmod +x scripts/start_all_services.sh
```

Run:
```bash
./scripts/start_all_services.sh up
```

For taking down all the services:
```bash
./scripts/start_all_services.sh down
```