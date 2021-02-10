# Simple server

A simple server that can be used to quickly create a chain of dockerized services that call each other.

## Usage

```
Usage: server [options]

Options:
  -V, --version                  output the version number
  -s, --service <name>           name of service
  -u, --upstream-service <name>  name of upstream service to invoke
  -e, --upstream-path <path>     Http path for upstream service
  -p, --port <port>              server port (default: "80")
  -h, --help                     output usage information
```

## Illustration

First, create a user-defined bridge network:
```
docker network create local
```

Next, create two containers named `front` and `middle`, with `middle` configured as the upstream service for `front`, and exposing `front` on port 8080.
```
docker run -d --name middle --network local simple-server node server -s middle
docker run -d --name front --network local -p 8080:80 simple-server node server -s front -u middle -e /middle
```

Test the health check endpoint for the `front` service:
```
curl localhost:8080/ping
```
This should return the response `ok`.

Test the `/front` endpoint:
```
curl localhost:8080/front?pretty=true
```
This should return:
```
{
  "Service": "front",
  "Upstream": {
    "Service": "middle"
  }
}
```

Now kill the `middle` container and re-test:
```
docker kill middle
docker rm middle
curl localhost:8080/front?pretty=true
```
This time the response should include an error response like:
```
{
  "Service": "front",
  "Upstream error": {
    "message": "getaddrinfo ENOTFOUND middle",
    "name": "Error",
    "stack": "Error: getaddrinfo ENOTFOUND middle\n    at GetAddrInfoReqWrap.onlookup [as oncomplete] (node:dns:69:26)",
    "config": {
      "url": "http://middle/middle",
      "method": "get",
      "headers": {
        "Accept": "application/json, text/plain, */*",
        "User-Agent": "axios/0.21.1"
      },
      "transformRequest": [
        null
      ],
      "transformResponse": [
        null
      ],
      "timeout": 0,
      "responseType": "json",
      "xsrfCookieName": "XSRF-TOKEN",
      "xsrfHeaderName": "X-XSRF-TOKEN",
      "maxContentLength": -1,
      "maxBodyLength": -1
    },
    "code": "ENOTFOUND"
  }
}
```

Now create a `back` service and re-create `middle` using `back` as upstream:
```
docker run -d --name back --network local simple-server node server -s back
docker run -d --name middle --network local simple-server node server -s middle -u back -e /back
```

Re-test:
```
curl localhost:8080/front?pretty=true
```
You should see:
```
{
  "Service": "front",
  "Upstream": {
    "Service": "middle",
    "Upstream": {
      "Service": "back"
    }
  }
}
```

To cleanup:
```
docker kill front middle back
docker rm front middle back
docker network rm local
```