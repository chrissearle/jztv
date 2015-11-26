#!/usr/bin/env ruby

require 'open-uri'
require 'json'
require 'logger'
require 'yaml'
require 'vimeo'

LOG = Logger.new(STDERR)

def get_value(data, key, part = 'value')
  selected = data.select { |d| d['name'] == key || d['rel'] == key }

  if selected && selected.count > 0
    selected[0][part]
  else
    nil
  end
end

def get_speakers(speakers)
  LOG.debug("Fetching speakers from #{speakers}")

  data = []

  speaker_data = JSON.parse(open(speakers).read)

  speaker_data['collection']['items'].each do |speaker|
    data << {
        :href => speaker_data['collection']['href'],
        :name => get_value(speaker['data'], 'name'),
        :bio => get_value(speaker['data'], 'bio')
    }
  end

  data
end

def get_sessions(sessions)
  LOG.debug("Fetching sessions for #{sessions[:name]} from #{sessions[:href]}")

  sessions[:sessions] = []
  session_data = JSON.parse(open(sessions[:href]).read)

  if (session_data['collection']['items'])
    LOG.debug(session_data['collection']['items'].count)

    session_data['collection']['items'].each do |session|
      data = {
          :href => session['href']
      }

      [:format, :body, :state, :published, :audience, :title, :lang, :summary, :level].each do |field|
        data[field] = get_value(session['data'], field.to_s)
      end

      data[:keywords] = get_value(session['data'], 'keywords', 'array')

      data[:video] = get_video(get_value(session['links'], 'alternate video', 'name'))

      data[:speakers] = get_speakers(get_value(session['links'], 'speaker collection', 'href'))

      sessions[:sessions] << data
    end
  else
    LOG.warn("No sessions seen for #{sessions[:name]}}")
  end

  sessions
end

def get_events(events)
  LOG.debug("Fetching events from #{events[:href]}")

  events[:sessions] = []

  event_data = JSON.parse(open(events[:href]).read)

  event_data['collection']['items'].each do |event|
    events[:sessions] << get_sessions(
        {:name => event['data'].select { |d| d['name'] == 'name' }[0]['value'],
         :href => event['links'].select { |l| l['rel'] == 'session collection' }[0]['href']
        })
  end

  events
end

def get_all_events
  get_events({:href => 'http://javazone.no/ems/server/events'})
end

def get_video(id)
  LOG.debug("Fetching video for #{id}")

  if id
    begin
      video = JSON.parse(Vimeo::Simple::Video.info(id).body)[0]

      {
          :id => video['id'],
          :url => video['url'],
          :thumbnail => video['thumbnail_large']
      }
    rescue JSON::ParserError => e
      LOG.warn("Video with id #{id} not available")
      nil
    end

  else
    nil
  end
end

def download
  events = get_all_events

  File.open('data.json', 'w') do |cache|
    cache.write(events.to_json)
  end
end
