# Example of a Crashing App in Node.JS

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

## Locate the image
Now look in your object storage and find the name of the zip file that was created.

e.g. a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.zip  

Each item in the name breaks down as
* a686e8f6-1b46-4e71-9d1a-3c65079ca686 - The guid to ensure the name is unique.
* dump - the type of zip
* 1634419098 - the time the dump occurred
* node-crasher - the name of the application (N.B this is truncated)
* 8 - The pid of the process 
* 4 - The signal that was sent to the process

## Start Debugging

Now you can run the `cdcli` command to start a debugging session.

An example command is:
```
cdcli -c a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.zip   -i quay.io/icdh/example-crashing-node-app
```

Where the `-c` option is the core zip file in the bucket.
The original image is referenced with the `-i` option.

A full list of config options can be seen by running 
```
cdcli --help
```

Once you have ran the cdcli command You will be presented with the following output.

```
Debugging: example-crashing-nodejs-app 
Runtime: nodejs 
Namespace: observe
Debug Image: quay.io/icdh/nodejs 
App Image: quay.io/icdh/example-crashing-nodejs-app 
Sending pod config using kubectl
stdout: debugger-06e3166c-f113-4291-81f8-8cf2839942c1
Defaulted container "debug-container" out of: debug-container, core-container
error: unable to upgrade connection: container not found ("debug-container")

Retrying connection...
Defaulted container "debug-container" out of: debug-container, core-container
```
If for some reason the container fails to start the you can kill the session by pressing `CTL-C`

Notice the cdcli will keep retrying to connect to the container if it isn't started yet.

You are now logged into a container on the kubernetes cluster and will see a command prompt.
```
[debugger@debugger-06e3166c-f113-4291-81f8-8cf2839942c1 debug]$ 
```
## Inspect the contents of the debug environment

Now run an `ls` command to see the content of the folder.
```
ls
a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4  a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.zip
init.sh  
rundebug.sh
```
You can see the folder containing the core dump and some helper scripts.
The `init.sh` script is used by the system to layout the folder structure and isn't needed for debugging.

Run the `env` command to see that the location of the core file and the executable are available as environment variables.

```
...
S3_BUCKET_NAME=cos-core-dump-store
EXE_LOCATION=/shared/node
PWD=/debug
HOME=/home/debugger
CORE_LOCATION=a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4/a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.core
...
```
## Start a debugging session
You can now start a debug session by simply running the `rundebug.sh` script.
```
./rundebug.sh
```
You will see the command that is ran and be given the lldb command prompt with the core and the exe preloaded.
```
(lldb) target create "/shared/node" --core "a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4/a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.core"
Core file '/debug/a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4/a686e8f6-1b46-4e71-9d1a-3c65079ca686-dump-1634419098-node-crasher-node-8-4.core' 
(x86_64) was loaded.
(lldb)
```

Now you are ready to start inspecting the core dump.

First you can now look at the backtrace by running the `v8 bt` command
```
v8 bt
 * thread #1: tid = 8, 0x0000000000983719 node`v8::base::OS::Abort() + 9, name = 'node', stop reason = signal SIGILL
  * frame #0: 0x0000000000983719 node`v8::base::OS::Abort() + 9
    frame #1: 0x0000000000d16331 node`v8::internal::Isolate::CreateMessageOrAbort(v8::internal::Handle<v8::internal::Object>, v8::internal::MessageLocation*) + 161
    frame #2: 0x0000000000d16475 node`v8::internal::Isolate::Throw(v8::internal::Object, v8::internal::MessageLocation*) + 309
    frame #3: 0x000000000109bc1c node`v8::internal::Runtime_Throw(int, unsigned long*, v8::internal::Isolate*) + 60
    frame #4: 0x0000000001446379 <exit>
    frame #5: 0x00000000014cc0dd <stub>
    frame #6: 0x00000000013dcea2 bar(this=0x4449d40b09:<Global proxy>, 0x38edbef53b81:<String: "hello world">) at /home/node/app/index.js:12:13 fn=0x000038edbef53b41
    frame #7: 0x00000000013dcea2 foo(this=0x4449d40b09:<Global proxy>, 0x38edbef53b81:<String: "hello world">) at /home/node/app/index.js:8:13 fn=0x000038edbef53b01
    frame #8: 0x00000000013dcea2 do_test(this=0x4449d40b09:<Global proxy>) at /home/node/app/index.js:3:17 fn=0x000038edbef53ac1
    frame #9: 0x00000000013dcea2 914182(this=0x38edbef51dd1:<Object: Object>, 0x38edbef51dd1:<Object: Object>, 0x38edbef535c9:<function: require at internal/modules/cjs/helpers.js:1:10>, 0x38edbef51be1:<Object: Module>, 0x38edbef50371:<String: "/home/node/app/i...">, 0x38edbef534f9:<String: "/home/node/app">) at /home/node/app/index.js:1:0 fn=0x000038edbef53271
    frame #10: 0x00000000013dcea2 914182(this=0x38edbef51be1:<Object: Module>, 0x38edbef53099:<String: "do_test()

```
You could use the long hand
```
thread backtrace all
```

You can see at the start that the program exited with a `SIGILL` or segmentation fault raised by the panic in our code.

The call stack represents the order of calls as they were executed before the panic.
Let's select the last call in our logic before the the first panic was raised.
In the example output that would be `frame #6`
Type the command or the line that corresponds to `bar(this=0x4449d40b09`
```
f 6
```
This is short hand for the following which can also be typed.
```
frame select 6
```
The output of either command will be 
```
node`Builtins_InterpreterEntryTrampoline:
->  0x13dcea2 <+194>: addb   %al, (%rax)
    0x13dcea4 <+196>: addb   %al, (%rax)
    0x13dcea6 <+198>: addb   %al, (%rax)
    0x13dcea8 <+200>: addb   %al, (%rax)
```

The output represents the currently selected frame and shows the instructions the machine code associated with the frame.
This isn't much use for debugging application level issues but the lldb v8 plugin can help us here.
With `v8 source list` we can see the javascript code associated with the frame.
```
v8 source list
  12 function bar(input) {
  13   console.log("{}", input);
  14   throw "Boom!";
  15 }
```

We can also use the v8 module to find counts of specific objects.

```
v8 findjsobjects 
```
Which gives us a list of the different types of objects when the container crashed.
```
 Instances  Total Size Name
 ---------- ---------- ----
          1         24 AbortError
          1         24 AsyncLocalStorage
          1         24 AsyncResource
          1         24 Blob
          1         24 DOMException
          1         24 Dir
          1         24 Dirent
          1         24 DirentFromStats
          1         24 ERR_INVALID_THIS
          1         24 FastBuffer
...
```
To see a full list of the commands available run 
```
v8 help
```

## Clean up
Now quit the debugger.
```
quit
```

And exit the pod 
```
exit
```

The debugging pod should now be deleted
```
pod "debugger-e2775f05-a5ff-4023-80fc-a14180c3b9e6" deleted
```
## Summary

Well done you've just done a core dump analysis on a Node.js application!
You should now be able to understand the benefits of capturing cores as they provide a very easy way to capture issues in environments that aren't easy to access and should also give you the confidence to panic applications when they reach an unknown state rather than trying to make erroneous computations.
