module FetchBot
  class Start < Grape::API
    get :start do
      @settings = Setting.first
      client = Slack::RealTime::Client.new

      client.on :hello do
        puts "Successfully connected, welcome '#{client.self['name']}' to the '#{client.team['name']}' team at https://#{client.team['domain']}.slack.com."
        channel = client.groups.detect { |c| c['name'] == @settings.name }['id']
        client.message channel: channel, text: 'Welcome to standup! Type "Start" to get started.'
      end

      client.on :message do |data|
        MessageSorter.sort_incomming_messages(data, client)
      end

      client.start!
    end
  end
end
