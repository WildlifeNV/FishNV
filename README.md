This repo will help you get the full version of FishNV running on you computer. You'll need the following:

* Docker Desktop (Windows or Mac)
* Git
* A copy of this repo on your computer/server/etc. ('git clone')
* A version of Make (not required, but will make this a bit easier)
* [maptiler account](https://www.maptiler.com/) 

## Getting Started

Once the required software is installed on your computer run the following to get FishNV running locally:

```bash
# clone the repo
git clone https://github.com/WildlifeNV/fishnv.git
cd FishNV
cp example.env .env
# add your maptiler key to the .env file after the cp command

# clone the db, api, app into the current directory
make clone

# run the applications
make up
```

### A Few Things To Know

> **Note**
> * The Makefile is used to get you setup quickly. It clones the `next` branch from the API and application. 
> * The `docker-compose` file uses volumes to mount the application directories into the containers. Any changes to the source code is reflected in the containers and should trigger a reload of the application (or API).
> * The database uses a SQL file backup from the production database for the data. However, a materialized view of the nearby waters takes awhile to run. So I've limited it to 100 waters for development. Depending on the resources allocated to Docker the full query could take upwards of 13 minutes to run.

## Building From "Scratch"

This process has many more steps to getting started. You'll need the following installed on you computer:

1. PostgreSQL
2. PostGIS with the necessary GDAL and GEOS bindings
3. NodeJS
4. Make
5. Clones of each repo for FishNV

*Windows user's, the easiest way to develop this is probably with the Windows Subsystem for Linux (WSL)*

Once those are installed and ready to go:

```bash
# clone the repos
git clone https://github.com/WildlifeNV/fishnv-database.git
git clone https://github.com/WildlifeNV/fishnv-api.git
git clone https://github.com/WildlifeNV/fishnv-app.git

# build the database, follow the steps in the database repo, this command requires 
# .pgpass and .pg_service.conf files in the root directory 
cd fishnv-database
SERVICE=fishnv@local make build

cd ..

# install dependencies for fishnv-api
cd fishnv-api
npm install
code .    # this will open visual studio
cd ..

## use the integrated terminal in visual studio code to run the application
npm run dev

# run the front-end application
cd fishnv-app
npm install
code .
cd ..

## use the integrated terminal in visual studio code to run the application
npm run dev
```

Once you've gotten all these commands to run you should be able to interact with the application.

## Development

You can use either installation method to develop the application. I am most familiar with the "from scratch" approach. Working with the `docker-compose` setup shouldn't be that different. 

Use feature branches to add new features or bug fixes. Merge these changes to `next` for testing, UAT. Once ready for deployment push to `main`.

Refer to each application repo to better understand how they work.

## Deployment

### Front-end

The front-end is deployed to AWS Amplify. Every new commit to the `main` branch will trigger a new deployment of the front-end application.

### API

The API is deployed as a container to an AWS ECS cluster. The cluster was provisioned using the AWS CDK, the repo is here: https://github.com/WildlifeNV/apis-infrastructure. Specifically, check the `lib/fishnv-stack.js` file to see the infrastructure deployed to run API. The container running the API is pulled from AWS ECR:

```js
// snippet from lib/fishnv-stack.js
/** Get the repo and image */
const repo = ecr.Repository.fromRepositoryArn(
  this,
  'EcrRepo',
  `arn:aws:ecr:${region}:${account}:repository/fishnv-api`
)
const image = ecs.ContainerImage.fromEcrRepository(repo, 'latest')
```

ECS is pulling the "latest" image tag from ECR. To trigger a new deployment:

1. Create a new image, tag with latest (and the SemVer found in the `package.json` of the API)
2. Push to AWS ECR
3. Run the following command from the AWS CLI to trigger a new deployment:
    ```sh
    aws ecs update-service \
    	--cluster backendServices \
    	--service fishnv_01 \
    	--force-new-deployment
    ```

*Note: this is a terrible way to trigger a new deployment. But it was a quick solution when that worked when I needed it.*

### Database

Write and test database migrations locally, then use Make or another tool to push them to the production database.
