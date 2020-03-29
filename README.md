# example-crashing-nodejs-app

A sample node app with an endpoint available to crash the app.

## usage

```
$ kubectl create deployment crashing-app --image=number9/example-crashing-nodejs-app
$ kubectl exec -it crashing-app-xxx -- /bin/sh
$ curl http://locahost:3000/
```
