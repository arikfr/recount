require 'goliath'
require 'em-synchrony/em-http'
require 'em-http/middleware/json_response'
require 'yajl'
require_relative 'counter'

module ReCount
  class Increment < Goliath::API

    def response(env)
      counter = ReCount::Counter.new params[:name]
      counter.increase

      [200, {'Content-Type' => 'application/json'}, counter.to_object]
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
