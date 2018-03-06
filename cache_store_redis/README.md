# CacheStoreRedis

Welcome to CacheStore! 

This is the redis implementation for cache_store.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cache_store_redis'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache_store_redis

## Environment Variables

 - **REDIS_KEEP_ALIVE_TIMEOUT** [Integer] [Default=30] This is the length of time in seconds a connection will be kept alive in the connection pool.
