# Twitter Favorites input plugin for Embulk

embulk-input-twitter_favorites is the Embulk input plugin for favorites tweet in Twitter.

## Overview

* **Plugin type**: input
* **Resume supported**: no
* **Cleanup supported**: no
* **Guess supported**: no

## Configuration

- **screen_name**: target screen_name (string, required)
- **consumer_key**: comsumer key of Twitter app (string, required)
- **consumer_secret**: comsumer secret of Twitter app (string, required)
- **access_token**: access token of Twitter app (string, required)
- **access_token_secret**: access token secret of Twitter app (string, required)

## Example

```yaml
in:
  type: twitter_favorites
  screen_name: 'screen_name'
  consumer_key: 'CONSUMER_KEY'
  consumer_secret: 'CONSUMER_SECRET'
  access_token: 'ACCESS_TOKEN'
  access_token_secret: 'ACCESS_TOKEN_SECRET'
```


## Build

```
$ rake
```
