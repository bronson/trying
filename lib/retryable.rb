module Retryable
  def retryable_options options=nil
    @retryable_options = options = nil if options == :reset   # for testing
    @retryable_options ||= {
      :tries     => 2,
      :on        => StandardError,
      :sleep     => 1,
      :matching  => /.*/,
    }

    @retryable_options.merge!(options) if options
    @retryable_options
  end

  def retryable options = {}, &block
    opts = retryable_options.merge options
    return nil if opts[:tries] < 1

    previous_exception = nil
    retry_exceptions = [opts[:on]].flatten
    retries = 0

    begin
      return yield retries, previous_exception
    rescue *retry_exceptions => exception
      raise unless exception.message =~ opts[:matching]
      raise if retries+1 >= opts[:tries]

      previous_exception = exception
      sleep opts[:sleep].respond_to?(:call) ? opts[:sleep].call(retries) : opts[:sleep]
      retries += 1
      retry
    end
  end
end
