# Router
This is the mini router used for env-setup via [Hono](https://hono.dev/) & [Cloudflare Workers/Wrangler](https://developers.cloudflare.com/workers/wrangler/).

## Setup
```
npm i

# configure env var creds per https://developers.cloudflare.com/workers/wrangler/system-environment-variables/#supported-environment-variables

# configure variables for wrangler 
export CLOUDFLARE_DOMAIN=example.com
export GITHUB_TOKEN="ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"
export GITHUB_ORG = "Octocat"

npm run config
```

## Dev
```
npm run dev
```

## Deploy
```
# configure variables for worker 
# add to https://developers.cloudflare.com/workers/configuration/environment-variables/#environment-variables-via-the-dashboard

npm run deploy
```

## Remove
```
npm run delete
```
