# Flight Inventory

Prototype app for visualising HPC clusters built with [Alces
Metalware](https://github.com/alces-software/metalware). Demo available at
http://staging.inventory.alces-flight.com.

## Development setup

```bash
git clone git@github.com:alces-software/flight-inventory.git
cd flight-inventory
bin/setup
```

Then in separate shells run:

- `bin/rails server` (back-end);
- `bin/webpack-dev-server` (front-end).

You will still need to import some data to have anything to visualise - see
below.

## To import Metalware data locally

Prerequisites:

1. Flight Inventory setup locally.

2. Access to an environment running Alces Metalware, at `$controller_ip`,
   where:
  - currently must be using the Metalware `develop` branch, or at least a
    version of Metalware post-merging of
    https://github.com/alces-software/metalware/pull/435;
  - must have nodes configured and assets associated with these;
  - you may want to use either of the following, available within the Alces
     office VPN:
     - `10.101.0.46` - simple asset example controller;
     - `10.101.0.36` - complex asset example controller.

Then run the following:

```bash
export ALCES_INSECURE_PASSWORD=$usual_password
rake alces:import IP=$controller_ip
```

Data will usually take quite a while to import, with the time increasing based
on the size of the cluster to be imported. You can start visualising things
shortly after the import has started however, you'll just need to rerun
`bin/rails server` first.


## To deploy to staging environment

```bash
git remote add staging dokku@apps.alces-flight.com:flight-inventory-staging
git push staging
```

You will then need to obtain database tables and data by some means (see
below).


## To import Metalware data to staging environment

Either of the following approaches should allow you to do this:

### Import a development database dump in the staging environment (recommended)

1. Follow the instructions in the ['To import Metalware data
   locally'](#to-import-metalware-data-locally) section.

2. Run the following commands:

  ```bash
  # On apps server.
  dokku run flight-inventory-staging bin/rake db:drop DISABLE_DATABASE_ENVIRONMENT_CHECK=1
  dokku run flight-inventory-staging bin/rake db:create

  # Locally.
  pg_dump -d postgres://postgres@localhost:5432/flight-inventory_development > /tmp/dump.sql
  psql -d $apps_server_rds_instance_url/flight-inventory-staging -f /tmp/dump.sql

  # On apps server.
  dokku ps:restart flight-inventory-staging
  ```

### Import directly to staging environment

1. Provide staging environment with access to the IP where the Metalware
   environment you want to import from is running, e.g. by SSH tunneling.

2. Follow the same instructions as in the ['To import Metalware data
   locally'](#to-import-metalware-data-locally) section, but within the staging
   environment.
