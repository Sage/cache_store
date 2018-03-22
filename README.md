# CacheStore

Welcome to CacheStore! 

This is the base for a cache framework that includes a basic in memory cache store, along with a dependency contract for additional provider implementations plugins.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'cache_store'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install cache_store

## Implementations

All cache store implementations adhere to the following contract:

    
	class CacheStore
		  
	  def set(key, value, expires_in = 0)
	
	  end
		  
	  def get(key, expires_in = 0, &block)
	
	  end
	 
	  def remove(key)
	
	  end

	  def exist?(key)
	
	  end
	end
	

**#set**

This method is called to store a value in the cache store for a unique key.

Params:

- **key** [String] 
This is the unique key to reference the value being set within this cache store
- **value** [Object]
This is the value to set within this cache store.
- **expires_in** [Integer] [Optional]
This is the number of seconds from the current time that this value should expire.

Example:

    #set with expires_in specified
    cache_store.set('country_code', 'en-GB', 180)
   

> The above example will store the **value** 'en-GB' under the **key**
> 'country_code' for **expiry** time of 180 seconds (2minutes). 
> Any requests to the cache_store for the 'country_code' key within the next 180 seconds (2minutes) will return the 'en-GB' value. 
> Requests for the key after the expiry time will return **nil** if no hydration block has been specified in the request.
>  If you don't specify an **expires_in** parameter then the value stored will not expire for the lifespan of the cache_store.

**#get**

This method is called to request a value from the cache store for a unique key.

Params:

- **key** [String]
This is the unique key of the value you want to fetch from within the cache store.
- **expires_in** [Integer] [Optional]
This is the number of seconds from the current time that this value should expire.

> (This is used in conjunction with the hydrate block to populate the cache key if it is empty.)

- **&block** [Block] [Optional]
This is the hydration block that when specified is used to populate the cache_store with the value for the specified key.

Examples:

    #example without a hydration block
    value = cache_store.get('country_code')

> This would return the **value** stored for the 'country_code' key or **nil** if the value had expired or was not found.

    #example with a hydration block
    value = cache_store.get('country_code', 180) do
    {
	    return 'en-GB'
    }

> This would execute the hydration block if the value was not found for the specified key or if the value had expired.

**#remove**

This method is called to remove a value from the cache store by it's unique key.

Params:

- **key** [String] This is the unique key of the item to remove from the cache store.

Example:

    cache_store.remove('country_code')


**#exist?**

This method is called to check if a value has been stored in the cache store for a specific key.

Params:

**key** [String]
This is the unique key of the value to check for.

Example:

    if cache_store.exist?('country_code')
	    ....do logic here
	end


##LocalCacheStore

The local cache store is a ruby in memory cache store that has no dependency on rails or any other frameworks. Multiple instances of the cache store can be created as required to maintain isolated cache stores, which are perfect for development and testing when your production application cache uses redis or memcached etc as a distributed cache.

    #create a new instance of the cache store
    cache_store = LocalCacheStore.new

> **CacheStore** works perfectly with **Sinject** a dependency injection framework allowing you to switch the cache store implementations used for different environments.

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/sage/cache_store. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

Cache Store is available as open source under the terms of the
[MIT licence](LICENSE).

Copyright (c) 2018 Sage Group Plc. All rights reserved.

