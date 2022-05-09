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
Update: You now also have to add the Spotify users that will do OAuth on here, limted to 24 accounts while the app is in development mode.

## 🔐 Google Auth
PR uses Google to authenticate users.
You will need keys for this too

# 🚀 Deployment


1. Create a Fly app
```sh
fly launch
```
It will probably ask if you want a postgres container as well. You do.

2. It might be useful to set the app name
```sh
export FLY_APP={app_name}
```

3. Build and push the image
```sh
fly deploy --remote-only --app $FLY_APP
```

4. You'll need to set the following env vars (see above for getting creds for Spotify and Sonos)
```sh
echo """
HOSTNAME={app_name}.fly.dev
REDIRECT_URL_BASE=https://{app_name}.fly.dev
SPOTIFY_CLIENT_ID=
SPOTIFY_SECRET=
SONOS_KEY=
SONOS_SECRET=
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
ALLOWED_USER_DOMAINS=
POOL_SIZE=10
INSTALLATION_NAME=PlayRequest
""" | fly secrets import --app $APP_NAME
```

5. It probably won't work first time, so logs help
```sh
fly logs  --app $FLY_APP
```

6. Login to create the first user

8. Using the database URL, connect to the database and set `trusted=TRUE` for your user.
You can then access the setup page to obtain access tokens and setup webhooks etc.
```sh
fly proxy 5433 --app ${FLY_APP}-db
```
Don't forget the proxy port!
