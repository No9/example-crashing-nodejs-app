# Example of a Crashing App in Rust

This repository is a how-to guide on debugging a crashing app using llnode and core-dump-handler.

## Prerequisites
This example assumes you have installed the [core-dump-handler](https://github.com/IBM/core-dump-handler/#installing-the-chart) into your kubernetes cluster.

Install the `cdcli` client on your machine. 
Download the latest build from releases https://github.com/IBM/core-dump-handler/releases page.Extract the `cdcli` from the zip folder and place it in a folder that is in your `$PATH`.

## Creating a core dump
To start with you need to generate a core dump. The code in the [example-crashing-nodejs-app](https://github.com/No9/example-crashing-nodejs-app/) project takes care of that.

The [project code](https://github.com/No9/example-crashing-nodejs-app/blob/main/index.js) has three nested calls inside a main function with the final call creating an explicit [`throw`](https://github.com/No9/example-crashing-nodejs-app/blob/main/index.js#L14).

Just enough for you to see how the call stack lays out for an application and do some investigation around that.

example-crashing-nodejs-app is a normal nodejs project with the following configuration in the [entrypoint.sh](https://github.com/No9/example-crashing-nodejs-app/blob/main/entrypoint.sh#L2). 

```
kubectl run -i -t node-crasher --image=quay.io/icdh/example-crashing-nodejs-app --restart=Never
```

