# Hello server

A simple web server that responds to the resource path `/hello/<name>` with a web page that displays a greeting and timestamp. 

## Illustration

Build the image:
```
docker build -t hello-server .
```

Run the server as follows:
```
docker run -p 8080:80 --name my-hello-server hello-server
```

Test the health check endpoint:
```
curl localhost:8080/ping
```
This should return the response `ok`.

Test the `/hello` endpoint:
```
curl localhost:8080/hello/bob
```
This should return:
```
Hi there bob<br>
<i>1617809127162</i>
```


To cleanup:
```
docker kill my-hello-server
docker rm my-hello-server
```