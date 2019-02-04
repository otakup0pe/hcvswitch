[![Build Status](https://travis-ci.org/otakup0pe/hcvswitch.svg?branch=master)](https://travis-ci.org/otakup0pe/hcvswitch)![Maintenance](https://img.shields.io/maintenance/yes/2019.svg)

HCV Switcher
============

These scripts provide a simple way of switching between different instances of Hashicorp Vault. Once integrated into someone's Bash dotfiles setup, it should keep some environment variables up to date. A key assumption made by this script is that the shell environment it is installed in has a function similar to `PS1_COMMAND` which runs each time the shell is generated. As the `VAULT_ADDR` is not stored in any files, this environment variable must be kept up to date.

Installation
------------

Clone this repository somewhere comfortable on your workstation. There are two environment variables which configure the scripts. Define these as you wish and then source the `init.sh` script in your `.profile`.

* `HCVSWITCH_PATH` points to the location you cloned this repository
* `HCVSWITCH_CONFIG` points to a yaml file containing your [Vault configuration](https://github.com/otakup0pe/hcvswitch#vault-configuration). This is optional and defaults to `~/.hcv.yml`.

#### `.profile Example`
```
export HCVSWITCH_PATH="${HOME}/src/hcvswitch"
export HCVSWITCH_CONFIG="${HOME}/.hcv.yml"
. "${HCVSWITCH_PATH}/init.sh"
```

There is an additional component that must be eval'd in the `PS1_COMMAND` context. This ensures that the Vault configuration is transparently known across terminals. Along with the various Vault environment variables, the `HCV_ENV` environment variable will be set to the name of the current Vault account. You can then use this to include the Vault environment in your `PS1` variable.

#### eval Example

```
eval $("${HCVSWITCH_PATH}/hcvswitch.sh" eval)
```

Vault Configuration
-------------------

The Vault configuration is stored in a simple yaml file. It is a list of config entries prefixed by a comment with the name of the Vault environment. The comment is the name referenced when switching Vault accounts. Note that only `id` and `url` are required. The values of `ignore_ssl` and `sni` have sensible defaults. You can also specify some authenticaiton hints with `auth_user` and `auth_method`.

```
#my-vault
- id: my-vault
  url: http://vault.example.com/
  ignore_ssl: false
  sni: vault.example.com
  auth_user: nobody
  auth_method: userpass
```

Script Actions
--------------

The inclusion of the `init.sh` script will keep some Vault related environment variables updated.

* `VAULT_ADDR` Will be set to the current `url` for the active Vault environment.
* `VAULT_SKIP_ADDR` Will be set to `0` or `1` depending on the `true`/`false` setting of the `ignore_ssl` for the active Vault environment.
* `VAULT_TLS_SERVER_NAME` will be set to either the value of the `sni` setting, or the hostname portion of the `VAULT_ADDR`.
* `HCV_ENV` will be set to the name of the current hcvswitch profile.

Usage
-----

Once you have initialized the script in your `.profile` usage is straight forward. Simply make use of the `hcvswitch` function and reference one of the Vault instances in your YAML configuration. This will cause your current terminal context to be re-initialized. Note that other terminals will _not_ be re-initialized until the next time the `PS1_COMMAND` context is evaluated. You can also use the `hcvlist` function to display the different Vault instances.

```
$ hcvlist
test1
test2
$ hcvswitch test1
$ echo $VAULT_ADDR
http://localhost:8200
$ hcvswitch test2
$ echo $VAULT_ADDR
http://localhost:8201
```

There is also a simple Vault authentication helper for the LDAP and userpass backends. This will associate a auth method and username with a profile. If you have set both `auth_user` and `auth_method` for a profile, the `hcvauth` command will initiate a `vault auth` request.

License
-----

[MIT](https://github.com/otakup0pe/hcvswitch/blob/master/LICENSE)

Author
-----
The hcvswitch tool was created by [Jonathan Freedman](http://jonathanfreedman.bio/).
