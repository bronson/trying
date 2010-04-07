module Retryable
  def retryable(options = {}, &block)
    opts = { :tries     => 1, 
             :on        => StandardError,
             :matching  => /.*/ }.merge(options)

    return nil if opts[:tries] == 0
  
    retry_exception = [opts[:on]].flatten
    tries           = opts[:tries]
    message_pattern = opts[:matching]
 
    begin
      return yield
    rescue *retry_exception => exception
      raise unless exception.message =~ message_pattern
      retry if (tries -= 1) > 0
    end
 
    yield
  end
end
