module Retryable
  def retryable(options = {}, &block)
    opts = { :tries     => 1, 
             :on        => StandardError,
             :sleep     => 0,
             :matching  => /.*/ }.merge(options)

    return nil if opts[:tries] == 0
  
    retry_exception = [opts[:on]].flatten
    tries           = opts[:tries]
    message_pattern = opts[:matching]
    sleep_time      = opts[:sleep]
 
    begin
      return yield
    rescue *retry_exception => exception
      raise unless exception.message =~ message_pattern

      if (tries -= 1) > 0
        sleep sleep_time
        retry
      end
    end
 
    yield
  end
end
