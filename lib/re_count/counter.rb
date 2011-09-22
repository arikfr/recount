require 'redis'

module ReCount
  class Counter
    attr_reader :name

    def initialize(name)
      @redis = self.class.redis_connection
      @name = name.to_s
      @value = 0
      super
    end

    def self.redis_connection
      @@redis_connection ||= Redis.new
    end

    def self.redis_connection=(redis_connection)
      @@redis_connection = redis_connection
    end

    def self.all
      redis_connection.smembers "counters"
    end

    def increase(value=1, day=Time.now)
      add_to_months_set(day)
      update_value_for_day(day, value)
    end

    def day_value(date=Time.now)
      @redis.hget(redis_key_for_month(date), date.day).to_i
    end

    def month_value(date=Time.now)
      month_value_by_key redis_key_for_month(date)
    end

    def year_value(date=Time.now)
      year = date.strftime('%Y')
      keys = @redis.zrangebyscore("#{redis_key}:months", "#{year}01", "#{year}12")
      months_value_by_keys(keys)
    end

    def total_value(date=Time.now)
      keys = @redis.zrange("#{redis_key}:months", 0, -1)
      months_value_by_keys(keys)
    end

    def to_object
      {
        name: name,
        day: day_value,
        month: month_value,
        year: year_value,
        total: total_value
      }
    end

    private
    def redis_key
      @redis_key ||= "counter:#{name}"
    end

    def redis_key_for_month(date)
      "#{redis_key}:#{date.strftime('%Y%m')}"
    end

    def month_value_by_key(key)
      @redis.hvals(key).map(&:to_i).inject(0) { |a,e| a+e }
    end

    def months_value_by_keys(keys)
      value = keys.inject(0) { |a,e| a+month_value_by_key(e) }
    end

    def update_value_for_day(date, value)
      @redis.hincrby(redis_key_for_month(date), date.day, value)
    end

    def add_to_months_set(date)
      @redis.sadd "counters", name
      @redis.zadd "#{redis_key}:months", date.strftime("%Y%m"), redis_key_for_month(date)
    end
  end
end
