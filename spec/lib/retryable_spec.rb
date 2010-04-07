require File.dirname(__FILE__) + '/../spec_helper'

describe "Retryable#retryable" do
  include Retryable

  it "should not affect the return value of the block given" do
    retryable { 'foo' }.should == 'foo'
  end

  it "should not affect the return value of the block given when there is a retry" do
    num_calls = 0
    ret_val = retryable do
      num_calls += 1
      raise Exception if num_calls == 1 # Raise error only the 1st time.
      'foo'
    end

    num_calls.should == 2
    ret_val.should == 'foo'
  end

  it "uses default options of :tries => 1 and :on => Exception when none is given" do
    num_calls = 0
    lambda {
      retryable do
        num_calls += 1
        raise Exception
      end
    }.should raise_error(Exception)

    num_calls.should == 2
  end

  it "does not retry if none of the retry conditions occur" do
    num_calls = 0
    retryable { num_calls += 1 }

    num_calls.should == 1
  end

  it "uses retries :tries times when the exception to retry on occurs every time" do
    num_calls = 0
    lambda {
      retryable(:tries => 3, :on => StandardError) do
        num_calls += 1
        raise StandardError
      end
    }.should raise_error(StandardError)

    num_calls.should == 4
  end

  it "should respect exception hierarchies (i.e. catch any subclass exceptions)" do
    num_calls = 0
    lambda {
      retryable(:on => StandardError) do
        num_calls += 1
        raise IOError if num_calls == 1 # Raise error only the 1st time.
      end

    }.should_not raise_error(IOError)

    num_calls.should == 2
  end
end