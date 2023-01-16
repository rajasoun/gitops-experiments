# Introduction to Containers, VMs and Docker      

Beginner-friendly introduction to the concepts of Virtual Machines (VMs), Containers, and Docker.

Introduction to Containers, VMs and Docker
==============================================================

A **Virtual Machine (VM)** is a software program that emulates a physical computer. It allows multiple operating systems to run on one physical machine by creating a virtual environment for each operating system. Each VM has its own operating system, resources, and applications, which are isolated from the host machine and other VMs.

A **container**, on the other hand, is a lightweight alternative to a VM. Instead of emulating a physical machine, a container uses the host machine's operating system and resources, but isolates the application and its dependencies in a separate environment. Containers share the host machine's kernel and do not require the overhead of a separate operating system.

In summary, a VM creates a virtual environment with its own operating system, while a container utilizes the host machine's operating system and isolates the application and its dependencies. This makes containers more lightweight and efficient than VMs.

### What are “containers” and “VMs”?

VMs emulate a complete hardware environment, while containers share the host machine's kernel and isolate the application and its dependencies. 

This makes containers more lightweight and efficient than VMs.


Virtual Machines (VMs) are software programs that emulate a physical computer, allowing multiple operating systems to run on one physical machine by creating a virtual environment for each operating system. 

Each VM has its own operating system, resources, and applications, which are isolated from the host machine and other VMs. 

VMs run on top of a physical machine using a "hypervisor", which is a piece of software, firmware, or hardware. Hypervisors provide a level of isolation and abstraction for applications and their dependencies, allowing them to run independently of the underlying hardware and operating system. Hosted hypervisors run on top of an existing operating system, while bare-metal hypervisors run directly on the host machine's hardware. 

The main benefit of using VMs is that they provide a level of isolation and abstraction for applications and their dependencies, allowing them to run independently of the underlying hardware and operating system.

![1*RKPXdVaqHRzmQ5RPBH_d-g](https://cdn-media-1.freecodecamp.org/images/1*RKPXdVaqHRzmQ5RPBH_d-g.png)

Virtual Machine Diagram

As you can see in the diagram, VMs package up the virtual hardware, a kernel (i.e. OS) and user space for each new VM.

### Container

Containers are a lightweight alternative to Virtual Machines (VMs) that allow for efficient packaging, shipping, and running of applications. They utilize the host machine's operating system and resources, but isolate the application and its dependencies in a separate environment called a container.

Containers share the host machine's kernel and do not require the overhead of a separate operating system, making them more lightweight and efficient than VMs. This also makes them more portable, as they can run on any system with a compatible container runtime, without the need for a specific operating system or configuration.

In summary, a container is a lightweight and portable way to package, ship and run applications, utilizing the host machine's operating system and resources, but isolating the application and its dependencies in a separate environment. They are more lightweight and efficient than VMs.

The one big difference between containers and VMs is that containers \*share\* the host system’s kernel with other containers.

![1*V5N9gJdnToIrgAgVJTtl_w](https://cdn-media-1.freecodecamp.org/images/1*V5N9gJdnToIrgAgVJTtl_w.png)

Container Diagram

This diagram shows you that containers package up just the user space, and not the kernel or virtual hardware like a VM does. Each container gets its own isolated user space to allow multiple containers to run on a single host machine. We can see that all the operating system level architecture is being shared across containers. The only parts that are created from scratch are the bins and libs. This is what makes containers so lightweight.

### Double-clicking on “containers”

Phew! That’s a lot of moving parts. One thing that always got me curious was how a container is actually implemented, especially since there isn’t any abstract infrastructure boundary around a container. After lots of reading, it all makes sense so here’s my attempt at explaining it to you! :)

The term “container” is really just an abstract concept to describe how a few different features work together to visualize a “container”. Let’s run through them real quick:

#### 1) Namespaces

Namespaces provide containers with their own view of the underlying Linux system, limiting what the container can see and access. When you run a container, Docker creates namespaces that the specific container will use.

There are several different types of namespaces in a kernel that Docker makes use of, for example:

a. **NET:** Provides a container with its own view of the network stack of the system (e.g. its own network devices, IP addresses, IP routing tables, /proc/net directory, port numbers, etc.).  
b. **PID:** PID stands for Process ID. If you’ve ever ran **ps aux** in the command line to check what processes are running on your system, you’ll have seen a column named “PID”. The PID namespace gives containers their own scoped view of processes they can view and interact with, including an independent init (PID 1), which is the “ancestor of all processes”.  
c. **MNT:** Gives a container its own view of the [“mounts” on the system](http://www.linfo.org/mounting.html). So, processes in different mount namespaces have different views of the filesystem hierarchy.  
d. **UTS:** UTS stands for UNIX Timesharing System. It allows a process to identify system identifiers (i.e. hostname, domainname, etc.). UTS allows containers to have their own hostname and NIS domain name that is independent of other containers and the host system.  
e. **IPC:** IPC stands for InterProcess Communication. IPC namespace is responsible for isolating IPC resources between processes running inside each container.  
f. **USER:** This namespace is used to isolate users within each container. It functions by allowing containers to have a different view of the uid (user ID) and gid (group ID) ranges, as compared with the host system. As a result, a process’s uid and gid can be different inside and outside a user namespace, which also allows a process to have an unprivileged user outside a container without sacrificing root privilege inside a container.

Docker uses these namespaces together in order to isolate and begin the creation of a container. The next feature is called control groups.

#### 2) **Control groups**

Control groups (also called cgroups) is a Linux kernel feature that isolates, prioritizes, and accounts for the resource usage (CPU, memory, disk I/O, network, etc.) of a set of processes. In this sense, a cgroup ensures that Docker containers only use the resources they need — and, if needed, set up limits to what resources a container \*can\* use. Cgroups also ensure that a single container doesn’t exhaust one of those resources and bring the entire system down.

Lastly, union file systems is another feature Docker uses:

#### 3) **Isolated Union file system:**

Described above in the Docker Images section :)

This is really all there is to a Docker container (of course, the devil is in the implementation details — like how to manage the interactions between the various components).

### Where does Docker come in?

Docker is an open-source project based on Linux containers. It uses Linux Kernel features like namespaces and control groups to create containers on top of an operating system.

Containers are far from new; Google has been using their own container technology for years. Others Linux container technologies include Solaris Zones, BSD jails, and LXC, which have been around for many years.

So why is Docker all of a sudden gaining steam?

1\. **Ease of use:** Docker has made it much easier for anyone — developers, systems admins, architects and others — to take advantage of containers in order to quickly build and test portable applications. It allows anyone to package an application on their laptop, which in turn can run unmodified on any public cloud, private cloud, or even bare metal. The mantra is: “build once, run anywhere.”

2\. **Speed:** Docker containers are very lightweight and fast. Since containers are just sandboxed environments running on the kernel, they take up fewer resources. You can create and run a Docker container in seconds, compared to VMs which might take longer because they have to boot up a full virtual operating system every time.

3\. **Docker Hub:** Docker users also benefit from the increasingly rich ecosystem of Docker Hub, which you can think of as an “app store for Docker images.” Docker Hub has tens of thousands of public images created by the community that are readily available for use. It’s incredibly easy to search for images that meet your needs, ready to pull down and use with little-to-no modification.

4\. **Modularity and Scalability:** Docker makes it easy to break out your application’s functionality into individual containers. For example, you might have your Postgres database running in one container and your Redis server in another while your Node.js app is in another. With Docker, it’s become easier to link these containers together to create your application, making it easy to scale or update components independently in the future.

Last but not least, who doesn’t love the Docker whale? ;)

![1*sGHbxxLdm87_n7tKQS3EUg](https://cdn-media-1.freecodecamp.org/images/1*sGHbxxLdm87_n7tKQS3EUg.png)

Source: [https://www.docker.com/docker-birthday](https://www.docker.com/docker-birthday)

### Fundamental Docker Concepts

Now that we’ve got the big picture in place, let’s go through the fundamental parts of Docker piece by piece:

![1*K7p9dzD9zHuKEMgAcbSLPQ](https://cdn-media-1.freecodecamp.org/images/1*K7p9dzD9zHuKEMgAcbSLPQ.png)

#### Docker Engine

Docker engine is the layer on which Docker runs. It’s a lightweight runtime and tooling that manages containers, images, builds, and more. It runs natively on Linux systems and is made up of:

1\. A Docker Daemon that runs in the host computer.  
2\. A Docker Client that then communicates with the Docker Daemon to execute commands.  
3\. A REST API for interacting with the Docker Daemon remotely.

#### Docker Client

The Docker Client is what you, as the end-user of Docker, communicate with. Think of it as the UI for Docker. For example, when you do…

you are communicating to the Docker Client, which then communicates your instructions to the Docker Daemon.

#### Docker Daemon

The Docker daemon is what actually executes commands sent to the Docker Client — like building, running, and distributing your containers. The Docker Daemon runs on the host machine, but as a user, you never communicate directly with the Daemon. The Docker Client can run on the host machine as well, but it’s not required to. It can run on a different machine and communicate with the Docker Daemon that’s running on the host machine.

#### Dockerfile

A Dockerfile is where you write the instructions to build a Docker image. These instructions can be:

*   **RUN apt-get y install some-package**: to install a software package
*   **EXPOSE 8000:** to expose a port
*   **ENV ANT\_HOME /usr/local/apache-ant** to pass an environment variable

and so forth. Once you’ve got your Dockerfile set up, you can use the **docker build** command to build an image from it. Here’s an example of a Dockerfile:

#### Docker Image

Images are read-only templates that you build from a set of instructions written in your Dockerfile. Images define both what you want your packaged application and its dependencies to look like \*and\* what processes to run when it’s launched.

The Docker image is built using a Dockerfile. Each instruction in the Dockerfile adds a new “layer” to the image, with layers representing a portion of the images file system that either adds to or replaces the layer below it. Layers are key to Docker’s lightweight yet powerful structure. Docker uses a Union File System to achieve this:

#### Union File Systems

Docker uses Union File Systems to build up an image. You can think of a Union File System as a stackable file system, meaning files and directories of separate file systems (known as branches) can be transparently overlaid to form a single file system.

The contents of directories which have the same path within the overlaid branches are seen as a single merged directory, which avoids the need to create separate copies of each layer. Instead, they can all be given pointers to the same resource; when certain layers need to be modified, it’ll create a copy and modify a local copy, leaving the original unchanged. That’s how file systems can \*appear\* writable without actually allowing writes. (In other words, a “copy-on-write” system.)

Layered systems offer two main benefits:

1\. **Duplication-free:** layers help avoid duplicating a complete set of files every time you use an image to create and run a new container, making instantiation of docker containers very fast and cheap.  
2\. **Layer segregation:** Making a change is much faster — when you change an image, Docker only propagates the updates to the layer that was changed.

#### Volumes

Volumes are the “data” part of a container, initialized when a container is created. Volumes allow you to persist and share a container’s data. Data volumes are separate from the default Union File System and exist as normal directories and files on the host filesystem. So, even if you destroy, update, or rebuild your container, the data volumes will remain untouched. When you want to update a volume, you make changes to it directly. (As an added bonus, data volumes can be shared and reused among multiple containers, which is pretty neat.)

#### Docker Containers

A Docker container, as discussed above, wraps an application’s software into an invisible box with everything the application needs to run. That includes the operating system, application code, runtime, system tools, system libraries, and etc. Docker containers are built off Docker images. Since images are read-only, Docker adds a read-write file system over the read-only file system of the image to create a container.

![1*hZgRPWerZVbaGT8jJiJZVQ](https://cdn-media-1.freecodecamp.org/images/1*hZgRPWerZVbaGT8jJiJZVQ.png)

Source: Docker

Moreover, then creating the container, Docker creates a network interface so that the container can talk to the local host, attaches an available IP address to the container, and executes the process that you specified to run your application when defining the image.

Once you’ve successfully created a container, you can then run it in any environment without having to make changes.

## Summary

In this article, we’ve covered the basics of Docker and how it works. 

VM is a software program that emulates a physical computer, allowing multiple operating systems to run on one physical machine by creating a virtual environment for each operating system. Each VM has its own operating system, resources, and applications, which are isolated from the host machine and other VMs.

Container is a lightweight alternative to a VM. Instead of emulating a physical machine, a container uses the host machine's operating system and resources, but isolates the application and its dependencies in a separate environment. Containers share the host machine's kernel and do not require the overhead of a separate operating system. The text also provides diagrams to illustrate the difference between VMs and Containers.

