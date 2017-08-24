# ansible-server

Ansible roles used to deploy services and web apps to a Debian Web server.

## Current roles
- nginx-proxy: https://github.com/jwilder/nginx-proxy
- traefik: https://docs.traefik.io/

## Usage

Create a configuration file by duplicating and editing config/example.yml

Run ansible using role and configuration file:

```bash
./ansible.sh --role=<role> --config=<filename>
```

Or:

```bash
./ansible.sh
```

Then choose a role:

```bash
1) traefik
2) nginx-proxy
Select a role:
```

And a configuration file:
```bash
1) /config/example.yml
2) /config/localhost.yml
3) /config/prod.yml
4) Quit
Please select a configuration file: 
```
