#!/usr/bin/env ruby

require 'sinatra'
require 'logger'
require 'json'
require 'time'

access_logger = ::Logger.new(STDOUT)
access_logger.level = ::Logger::WARN



configure do
  use ::Rack::CommonLogger, access_logger
  enable :dump_errors
  enable :show_exceptions

end

get '/hi' do
  "Hello World!"
end

post '/:source/:type' do
  request.body.rewind #- not sure if this is breaking the json parse.
  payload = JSON.parse(request.body.read) #,:symbolize_names => true)
  logger.info "PAYLOAD: #{JSON.pretty_generate(payload)}"

  runner_dir = '/srv/capsulecd'

  # lets download all its gem dependencies
  Bundler.with_clean_env do
    Open3.popen3('bundle install', :chdir => runner_dir) do |stdin, stdout, stderr, external|
      {:stdout => stdout, :stderr => stderr}. each do |name, stream_buffer|
        Thread.new do
          until (line = stream_buffer.gets).nil? do
            puts "#{name} -> #{line}"
          end
        end
      end
      #wait for process
      external.join
      if !external.value.success?
        raise 'bundle install failed. Check gem dependencies'
      end
    end

    require_relative "/srv/capsulecd/#{params['type']}/#{params['type']}_engine.rb"
    engine = ChefEngine.new(params['source'])
    engine.start(payload)


  end


  return 'success'
end
