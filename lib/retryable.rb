module Retryable
  def retryable( options = {}, &block )
    opts = { :tries => 1, :on => StandardError }.merge(options)

    return nil if opts[:tries] == 0
  
    retry_exception, tries = [ opts[:on] ].flatten, opts[:tries]
 
    begin
      return yield
    rescue *retry_exception
      retry if (tries -= 1) > 0
    end
 
    yield
  end
end
