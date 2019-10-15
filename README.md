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
This repo has stuff for deploying on Heroku using Elixir Releases and the Heroku Elixir buildpack.
Environment variables are loaded in at run time from `rel/envvars.exs`
Annoyingly because of the way the buildpack runs, the asset digest happens when the dyno starts (not at build time currently).

# 📝 Migrate

```sh
heroku run "./migrate.sh"
```

