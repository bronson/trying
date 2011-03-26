# Retryable

Run a code block and automatically retry when an exception occurs.

    retryable(:tries => 3, :on => IOError) do
        read_flaky_sector
    end

This will call read_flaky_sector up to 3 times and either return the result
if succeeds or pass the last exception if it fails.


## Install

* Bundler: `gem "retryable", :git => "git://github.com/bronson/retryable.git"`

You must include retryable before using it.
This allows unrelated libraries to use retryable without conflicting.
To use it globally:

    require "retryable"
    include Retryable


## Options

Retryable uses these defaults:

* :tries => 2
* :on => StandardError
* :sleep => 1
* :matching => /.\*/

    $ ruby -r ./lib/retryable.rb -e "include Retryable; puts Retryable.retryable_options.inspect"

You can pass options to the retryable command (see above) or
use retryable_options to change the defaults:

    retryable_options :tries => 5, :sleep => 20
    retryable { catch_dog }

This will make 5 attempts, potentially sleeping for a total of 80 seconds.


## Sleeping

By default Retryable waits for one second between retries.  You can change this:

    retryable(:sleep => 0) { }                # don't pause at all between retries
    retryable(:sleep => 10) { }               # sleep ten seconds between retries
    retryable(:sleep => lambda { |n| 4**n }) { }   # sleep 1, 4, 16, etc. each try


## Exceptions

By default Retryable will retry any exception that inherits from StandardError.
This catches most runtime errors (IOError, floating point) but lets most
other errors (missing method, nil reference) pass.

You probably only want to retry specific exceptions and let anything unexpected
filter upward:

    :retryable(:on => [IOError, RangeError]) { ... }

More on Ruby exceptions:

 * <http://blog.nicksieger.com/articles/2006/09/06/rubys-exception-hierarchy>
 * <http://www.zenspider.com/Languages/Ruby/QuickRef.html#34>

You can also retry based on the exception message:

    :retryable(:matching => /export/) { ... }


## Block Parameters

Your block is called with two optional parameters: the number of tries until now,
and the most recent exception:

    retryable { |retries, exception|
      puts "try #{retries} failed: #{exception}" if retries > 0
      pick_up_soap
    }


## Nesting

Accidentally nesting callbacks can be a real problem.  What you thought was
a 6 minute maximum delay could end up being 36 minutes or worse.
Nesting detection is off by default but it's easy to turn on.

    retryable(:detect_nesting => true) {
      retryable { thread_needle }   # thread_needle will never be called
    }

When Retryable detects nesting, it throws an Exception, not a StandardError.
This way the error should propagate all the way out.  Beware, if your outer
loop specifies :on => Exception, your inner loop will raise the NestedException
and your outer one will happily keep retrying it!


## Examples

Open an URL, retry up to two times when an `OpenURI::HTTPError` occurs.

    require "retryable"
    require "open-uri"

    include Retryable

    retryable(:tries => 3, :on => OpenURI::HTTPError) do
      xml = open("http://google.com/").read
    end


## License

Public domain.


## History

The story until now...

* 2008 [Cheah Chu Yeow](https://github.com/chuyeow/try)
  wrote retryable as a monkeypatch to Kernel and wrote a
  [blog post](http://blog.codefront.net/2008/01/14/retrying-code-blocks-in-ruby-on-exceptions-whatever/).
* 2009 [Carlo Zottmann](https://github.com/carlo/retryable)
  converted it to a gem and made it a separate method.
* 2010 [Songkick](https://github.com/songkick/retryable)
  converted it to a module and added :matching and :sleep.
* 2011 [Scott Bronson](https://github.com/bronson/retryable)
  rebased onto orig repo, added some features and cleanups.

