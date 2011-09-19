require 'goliath'
require 'em-synchrony/em-http'
require 'em-http/middleware/json_response'
require 'yajl'
require_relative 'counter'

unless ENV["REDISTOGO_URL"].nil?
  uri = URI.parse(ENV["REDISTOGO_URL"])
  ReCount::Counter.redis_connection = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
end

module ReCount
  class Increment < Goliath::API

    def response(env)
      counter = ReCount::Counter.new params[:name]
      new_value = counter.increase

      [200, {'Content-Type' => 'application/json'}, {day: new_value}]
    end

  end

  class Values < Goliath::API

    def response(env)
      counter = ReCount::Counter.new params[:name]

      [200, {'Content-Type' => 'application/json'}, counter.to_object]
    end

  end

  class Server < Goliath::API
    use Goliath::Rack::Params
    use Goliath::Rack::Formatters::JSON

    post '/counters/:name/increment' do
      run Increment.new
    end

    get '/counters/:name' do
      run Values.new
    end

    not_found('/') do
      run Proc.new { |env| [404, {"Content-Type" => "text/html"}, ["This is not the page you were looking for."]] }
    end
  end
end
