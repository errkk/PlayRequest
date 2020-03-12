# ![PlayRequest](https://github.com/errkk/PlayRequest/raw/master/apps/pr_web/assets/static/images/favicon.png) PlayRequest

PlayRequest is a shared play queue for people who work together but not well enough to use the Sonos Queue properly.
Using the Spotify API to search tracks, users can queue stuff up into a shared queue that gets played on the Sonos via the Sonos Control API.

These are both official APIs so this project is a little different to the ones that intercept the Sonos's local SOAP based api that seems to have changed recently, making a lot of Sonos scripting solutions un workable (for the time being) 😢.

PlayRequest uses Phoenix LiveView for keeping the UI up to date with the playback progress and dynamic queue.
Players can show eachother appreciation for good tune choice by pressing a little heart, to give the chooser a good behaviour afferming dopamin hit.

![PlayRequest Screenshot](https://github.com/errkk/PlayRequest/raw/master/docs/play-request-screenshot.png)

# 👩‍💻 Running locally
You'll need to get a bunch of API keys.
Rename `.env.example` to `.env` and put in all the secret stuff.

## 🔈 Sonos
Go to [Sonos Developers](https://integration.sonos.com/integrations)
and create a control integration, get the credentials to put in `.env`.
Don't forget to set a redirect url. For development this can be localhost, as it is used for OAuth.

e.g. `http://localhost:4000/sonos/authorized`

You will also need to set a callback url, this will need to be proxied as it is for webhooks to update PR of the playback status

eg: `https://{YOUR PROXY HOST}/sonos/callback`

## 🎵 Spotify
Go to [Spotify Developers](https://developer.spotify.com/documentation/web-api/) and create a web API integration

## 🔐 Google Auth
PR uses Google to authenticate users.
You will need keys for this too

# 🚀 Deployment
Environment variables are loaded in at run time from `rel/envvars.exs`
The GitHub actions workflow for this repo will build an Elixir release and then slip it into an Alpine Docker image which it pushes to the package registry `docker.pkg.github.com`.

# Heroku
To install your own PR on Heroku, you can deploy the container.

1. Create a Heroku app
```sh
heroku apps:create {app_name} --region=eu --stack=container --no-remote
```

2. Pull the image from GitHub
```sh
docker pull docker.pkg.github.com/errkk/playrequest/pr:latest
```

3. Tag it to your Heroku app's registry
```sh
docker tag docker.pkg.github.com/errkk/playrequest/pr:build registry.heroku.com/{app_name}/web
```

4. You'll need to set the following env vars (see above for getting creds for Spotify and Sonos)
```sh
heroku config:set --app={app_name} HOSTNAME={app_name}.herokuapp.com
heroku config:set --app={app_name} REDIRECT_URL_BASE=https://{app_name}.herokuapp.com
heroku config:set --app={app_name} SPOTIFY_CLIENT_ID=
heroku config:set --app={app_name} SPOTIFY_SECRET=
heroku config:set --app={app_name} SONOS_KEY=
heroku config:set --app={app_name} SONOS_SECRET=
heroku config:set --app={app_name} GOOGLE_CLIENT_ID=
heroku config:set --app={app_name} GOOGLE_CLIENT_SECRET=
heroku config:set --app={app_name} ALLOWED_USER_DOMAINS=
heroku config:set --app={app_name} POOL_SIZE=10
heroku config:set --app={app_name} INSTALLATION_NAME=PlayRequest
```

5. Make a database for the app
```sh
heroku addons:create heroku-postgresql
heroku labs:enable runtime-dyno-metadata
```

5.  Then release the image using the Heroku CLI
```sh
heroku container:release web -a {app_name}
```

6. Make sure to migrate the database (see below)

7. Login to create the first user

8. Using the database URL, connect to the database and set `trusted=TRUE` for your user.
You can then access the setup page to obtain access tokens and setup webhooks etc.

# 📝 Migrate
There's a shell script in the container that will migrate the database
```sh
heroku run "./migrate.sh"
```

