# Trying

Execute a code block until it succeeds.  Punch it until it yields.

TODO: change these to trying
[![Build Status](https://api.travis-ci.org/bronson/retryable.png?branch=master)](http://travis-ci.org/bronson/retryable)
[![Coverage Status](https://coveralls.io/repos/bronson/retryable/badge.png?branch=master)](https://coveralls.io/r/bronson/retryable)
[![Code Climate](https://codeclimate.com/github/bronson/retryable.png)](https://codeclimate.com/github/bronson/retryable)
[![Dependency Status](https://gemnasium.com/bronson/retryable.png)](https://gemnasium.com/bronson/retryable)

    require "trying"

    module DiskBox
      include Trying

      trying 3.times, :on => IOError do
       read_floppy
      end
    end

If read_floppy raises an IOError, it will be called twice more before giving up.


## Install

* `gem 'trying'`

Then include it in the module or class that will call it.
This allows unrelated libraries to use their own defaults without conflict.

You can include it globally if laziness is a virtue:

    require "trying"
    include Trying
    trying_options detect_nesting: true


## Sleeping

There is normally a one second delay between retries.  You can change this,
even providing your own exponential backoff scheme.

    trying(:sleep => 0) { }                    # no pause between retries
    trying(:sleep => 10) { }                   # sleep ten seconds between retries
    trying(:sleep => lambda { |n| 4**n }) { }  # sleep 1, 4, 16, etc. each try
    trying(:sleep => nil) { }                  # don't even call sleep


## Exceptions

Retryable retries any exception that inherits from StandardError.
This catches most runtime errors (IOError, floating point) but lets most
more catastrophic errors (missing method, nil reference) pass through without
being retried.

Generally you only want to retry a few specific errors anyway:

    trying(:on => [IOError, RangeError]) { ... }

You can certainly retry everything but, be warned, this is probably not what you want!
Do you really want to retry method missing, out of memory, and a whole range of other
errors that can't be fixed by trying again?

    trying(:on => Exception) { ... }

More on Ruby exceptions:

 * <http://blog.nicksieger.com/articles/2006/09/06/rubys-exception-hierarchy>
 * <http://www.zenspider.com/Languages/Ruby/QuickRef.html#34>

You can also retry based on the exception message:

    trying(:matching => /export/) { ... }


## Parameters

Your block is called with two optional parameters: the number of tries until now,
and the most recent exception.

    retryable { |retries, exception|
      puts "try #{retries} failed: #{exception}" if retries > 0
      pick_up_soap
    }


## Logging

retryable offers a little logging assistance if you specify a task.

    retryable(:task => 'pick up sticks') { raise IOError }

Prints:

    pick up sticks
    pick up sticks RETRY 1 because IOError

Use :logger to change the log message or destination:

    retryable_options :logger => lambda { |task,retries,error|
        logger.error "retry #{task} #{retries}: #{error}" if retries > 0
    }


## Nesting

Accidentally nesting callbacks can be a real problem.  What you thought was
a 6 minute maximum delay could end up being 36 minutes or worse.
Nesting detection is off by default but it's easy to turn on.

    retryable(:detect_nesting => true) {
      retryable { thread_needle }   # thread_needle will never be called
    }

When Retryable detects a nested call it throws a Retryable::NestedException.
This is not a StandardError, so it's not retried by default, and the error
will propagate out.


## Disabling

If you set :tries to 0 then your block won't be called at all.
You can use this to temporarialy disable all your retryable blocks:

    retryable_options :tries => 0


## Options

These are the default options:

* :tries => 2  # try the call once, then retry once
* :on => StandardError
* :sleep => 1
* :matching => /.\*/
* :detect_nesting => false
* :logger => lambda { |task,retries,error| ... }  # only logs if you specify a :task
* :task => nil

You can pass custom settings every time you call the retryable command,
or call retryable_options to change the default settings:

    retryable_options :tries => 5, :sleep => 20
    retryable { catch_dog }


## Examples

Open an URL, retry up to two more times when an `OpenURI::HTTPError` occurs.

    require "trying"
    require "open-uri"

    include Trying

    trying 3.times, :on => [OpenURI::HTTPError, Errno::ECONNRESET] do
      xml = open("http://google.com/").read
    end

Print the default settings:

    ruby -r ./lib/retryable.rb -e "include Retryable; puts Retryable.retryable_options.inspect"


## Alternatives

* NodeJS: <https://github.com/tim-kos/node-retry>
* Robert Sosinnski's Retryable: https://github.com/robertsosinski/retryable
* Nikita Fedyashev's Retryable: https://github.com/nfedyashev/retryable
* Richard Schneeman's Rrrretry: https://github.com/schneems/rrrretry
* Haakon Sorensen's Retry: http://retry.rubyforge.org/

## License

Confirmed by Chu Yeow: MIT or public domain, your choice.


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
  rebased it back onto Chu's repo, added flexible sleep and nesting detection.
* 2012 [Nikita Fedyashev](https://github.com/nfedyashev/retryable)
  resurrected Carlo's repo and made a new retryable gem release.
* 2013 [Scott Bronson](https://github.com/bronson/trying)
  renamed his fork to trying and released a gem.
