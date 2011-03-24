require File.dirname(File.absolute_path(__FILE__)) + '/spec_helper'

describe "Retryable#retryable" do
  include Retryable

  def count_retryable *opts
    @count = 0
    return retryable(*opts) { |*args| @count += 1; yield *args }
  end

  it "should not affect the return value of the block" do
    count_retryable { 'foo' }.should == 'foo'
    @count.should == 1
  end

  it "should not affect the return value when there is a retry" do
    count_retryable { |tries| raise StandardError if tries < 1; 'foo' }.should == 'foo'
    @count.should == 2
  end

  it "passes the exception to the application" do
    lambda { count_retryable { raise IOError } }.should raise_error IOError
    @count.should == 2
  end

  it "should not catch Exceptions by default" do
    lambda { count_retryable { raise Exception } }.should raise_error Exception
    @count.should == 1
  end

  it "retries the specified number of times" do
    lambda { count_retryable(:tries => 3) { raise StandardError } }.should raise_error StandardError
    @count.should == 4
  end

  it "retries exceptions that are covered by :on" do
    # FloatDomainError is a subclass of RangeError
    lambda { count_retryable(:on => RangeError) { raise FloatDomainError } }.should raise_error FloatDomainError
    @count.should == 2
  end

  it "doesn't retry exceptions that aren't covered by :on" do
    # NameError is a sibliing of RangeError, not a subclass
    lambda { count_retryable(:on => RangeError) { raise NameError } }.should raise_error NameError
    @count.should == 1
  end

  it "should catch an exception that matches the regex" do
    count_retryable(:matching => /IO timeout/) { |c| raise "yo, IO timeout!" if c == 0 }
    @count.should == 2
  end

  it "should not catch an exception that doesn't match the regex" do
    lambda { count_retryable(:matching => /TimeError/) { raise "yo, IO timeout!" } }.should raise_error RuntimeError
    @count.should == 1
  end

  it "with all the options set" do
    count_retryable(:tries => 3, :on => RuntimeError, :sleep => 0.3, :matching => /IO timeout/) { |c| raise "my IO timeout" if c < 3 }
    @count.should == 4
  end
end
