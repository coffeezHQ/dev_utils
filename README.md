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

- All services will start in the background.
- Logs for each service will be written to `$COFFEEZ_ROOT/logs/` as separate `.log` files.
- To view logs for a service, use:
  ```bash
  tail -f $COFFEEZ_ROOT/logs/<service>.log
  # e.g.
  tail -f $COFFEEZ_ROOT/logs/creators-studio-api.log
  tail -f $COFFEEZ_ROOT/logs/creators-studio.log
  tail -f $COFFEEZ_ROOT/logs/db-migrations.log
  tail -f $COFFEEZ_ROOT/logs/kafka-consumer.log
  ```

For taking down all the services and clearing logs:
```bash
./scripts/start_all_services.sh down
```
- This will stop all services and delete all log files in `$COFFEEZ_ROOT/logs/`.