### How to install opam-health-check:

```
$ opam pin add opam-health-check .
```

### How to use opam-health-check locally:

For opam-health-check to work you need to start the server like so:
```
$ opam-health-serve <a new clean path or a path to an existing work directory>
```
For instance:
```
$ opam-health-serve /tmp/opam-health-check
```

Now simply use the `opam-health-check` command. First we need to initialize it like so:
```
$ opam-health-check init --from-local-workdir /tmp/opam-health-check
```
or used any custom path given to the server.

Now you can send any command to the server using the `opam-health-check` command.
All subcommands are listed with `opam-health-check --help`.

### Basic Setup

The server contains some state to know what to run. The `opam-health-check` command allows you 
to set that state. Note that some state **must** be set before you can run anything otherwise 
errors ensue. 

The first one you want to set is the OCaml switch with a `NAME` and the compiler version. This is 
by default the only one you will need. For example: 

```
opam-health-check add-ocaml-switch 4.11.1 4.11.1
```

### OCluster capability file

opam-health-check now uses [OCluster](https://github.com/ocurrent/ocluster) for its daily use. 
This means you need access to an OCluster instance. 

For local testing the easiest way to do this is to vendor in OCluster directly in the repository.
This allows you to tweak it if necessary. To get up and running you'll need to follow the steps 
in the [OCluster README](https://github.com/ocurrent/ocluster). But the basic outline is: 

  1. Start the scheduler service (probably pointing most addresses to local host) and adding a pool.
  2. Add a worker to that pool, for most people this will be a [runc](https://github.com/opencontainers/runc) 
  and [btrfs](https://btrfs.wiki.kernel.org/index.php/Main_Page) worker.
  3. Generate the submission `.cap` file for opam-health-check to use to submit jobs to the cluster, 
  move this file to `~/ocluster.cap` (this may change in the future).
  4. You are now ready to run `opam-health-check run`.

### How to use opam-health-check remotely:

As with local opam-health-check you need to have a server started somewhere and accessible.
Don't forget to open the admin and http ports. Default ports are respectively 6666 and 8080.
You can change them by modifying the yaml config file at the root of the work directory and
restarting the server.

During the first run the server creates an admin user and its key.
To connect to the server remotely just you first need to retreive the `admin.key` file located
in `<workdir>/keys/admin.key` and do `opam-health-check init`.
From there, answer all the questions (hostname, admin-port (default: 6666), username (admin)
and the path to the user key you just retreived).
You now have your client tool configured with an admin user !

To add new users, just use the `opam-health-check add-user <username>` command as the admin and
give the key to your new user. She now just need to do the same procedure but with her username.

Side note: every users have the same rights and can add new users.

Enjoy.
