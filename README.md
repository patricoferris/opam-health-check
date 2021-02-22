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
All subcommands are listed with `opam-health-check --help`

### OCluster capability file

opam-health-check now uses OCluster for its daily use. This means you need access to an
OCluster instance and you also need to place its dedicated capability file to `~/ocluster.cap`
on the server (will change in the future).

To set this up locally, you will need to get run the OCluster scheduler and one or more workers. The 
sequence of steps is: 

1. Run the OCluster scheduler probably with the public address `tcp:127.0.0.1:9000`.
2. Use the OCluster admin command to generate the submission capability for opam-health-check, it will most likely be something like `ocluster-admin add-client ./capnp-secrets/admin.cap opam-health-check > ~/ocluster.cap`.
3. Add a new worker to the pool you are using.
4. Run the opam-health-check server.
5. Initialise opam-health-check as described above, add some switches and then run the checks.

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
