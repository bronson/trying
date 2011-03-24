module Retryable
  def retryable_options options=nil
    @retryable_options ||= {
      :tries     => 1,
      :on        => StandardError,
      :sleep     => 0,
      :matching  => /.*/,
    }

    @retryable_options.merge!(options) if options
    @retryable_options
  end

  def retryable options = {}, &block
    opts = retryable_options.merge options
    return nil if opts[:tries] < 1

    previous_exception = nil
    retry_exception = [opts[:on]].flatten
    retries = 0

    begin
      return yield retries, previous_exception
    rescue *retry_exception => exception
      raise unless exception.message =~ opts[:matching]

      retries += 1
      raise if retries > opts[:tries]

      previous_exception = exception
      sleep opts[:sleep]
      retry
    end
  end
end
