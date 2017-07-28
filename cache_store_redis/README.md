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

 - **CACHE_STORE_POOL_SIZE** [Integer] [Default=10] This is the max number of cache_store connections to redis to allow in the connection pool.
 - **CACHE_STORE_POOL_TIMEOUT** [Integer] [Default=1] This is the max number of seconds to wait for a connection from the pool before a timeout occurs.
  