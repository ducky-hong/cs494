Usage
-----

```bash
# nbase-arc docker image has restarting issue.
$ docker-compose up --force-recreate

# manual tasks

# ngrinder-agent cannot download at initial startup
$ docker-compose start ngrinder-agent
# start hubblemon client
$ docker exec cs494_hubblemon_1 /bin/bash -c "python /usr/src/app/collect_client/run_client.py"
```
