`docker-compose.yml` sample:

```yaml
version: '2'

services: 
  teamcity:
    image: glivron/teamcity

  teamcity-agent-1:
    image: glivron/teamcity-agent
    links:
      - teamcity

  teamcity-agent-2:
    image: glivron/teamcity-agent
    links:
      - teamcity

  teamcity-agent-3:
    image: glivron/teamcity-agent
    links:
      - teamcity
```
