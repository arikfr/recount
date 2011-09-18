$:.push File.expand_path(File.dirname(__FILE__) + '/../lib')

module InstancesKeeper
  module ClassMethods
    def instances
      @instances ||= []
    end
  end

  def self.included(base)
    base.extend ClassMethods
  end

  def initialize(*args)
    self.class.instances << self
    super(*args)
  end
end

module ReCount
  class Counter
    include InstancesKeeper
  end
end

RSpec.configure do |config|
  if ENV['TRAVIS']
    config.before(:each) do
      Redis.new.flushall
    end
  else
    ROOT_PATH = File.expand_path(File.dirname(__FILE__) + '/../')
    REDIS_PID = "#{ROOT_PATH}/tmp/pids/redis-test.pid"
    REDIS_CACHE_PATH = "#{ROOT_PATH}/tmp/cache/"

    config.before(:suite) do
      redis_options = {
        "daemonize"     => 'yes',
        "pidfile"       => REDIS_PID,
        "port"          => 9736,
        "timeout"       => 300,
        "save 900"      => 1,
        "save 300"      => 1,
        "save 60"       => 10000,
        "dbfilename"    => "dump.rdb",
        "dir"           => REDIS_CACHE_PATH,
        "loglevel"      => "debug",
        "logfile"       => "stdout",
        "databases"     => 16
      }.map { |k, v| "#{k} #{v}" }.join('\n')
      `echo '#{redis_options}' | redis-server -`
    end

    config.before(:each) do
      Redis.new(:port => 9736).flushall
    end

    config.after(:suite) do
      %x{
        cat #{REDIS_PID} | xargs kill -QUIT
        rm -f #{REDIS_CACHE_PATH}dump.rdb
      }
    end

    require 're_count/counter'
    ReCount::Counter.redis_connection = Redis.new(:port => 9736)
  end
end
