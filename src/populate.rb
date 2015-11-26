#!/usr/bin/env ruby

require 'json'
require 'logger'
require 'elasticsearch'

CLIENT = Elasticsearch::Client.new log: true
LOG = Logger.new(STDERR)

def process_sessions(sessions, name)
  if sessions.count > 0
    sessions.each do |session|
      session['conference'] = name
      session['id'] = session['href']
      CLIENT.index index: 'videos', type: 'session', id: session['href'], body: session
    end
  else
    LOG.warn("Found no sessions for #{name}")
  end
end

def process_events(events)
  events.each do |event|
    process_sessions(event['sessions'], event['name'])
  end
end

def mapping
  CLIENT.indices.put_mapping index: 'videos', type: 'session', body: {
      session: {
          properties: {
              audience: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              body: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              conference: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              format: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              href: {
                  type: 'string',
                  index: 'not_analyzed'
              },
              keywords: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              lang: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              level: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              published: {
                  type: 'boolean',
                  index: 'not_analyzed'
              },
              speakers: {
                  properties: {
                      bio: {
                          type: 'string',
                          fields: {
                              raw: {
                                  type: 'string',
                                  index: 'not_analyzed'
                              }
                          }
                      },
                      href: {
                          type: 'string',
                          index: 'not_analyzed'
                      },
                      name: {
                          type: 'string',
                          fields: {
                              raw: {
                                  type: 'string',
                                  index: 'not_analyzed'
                              }
                          }
                      }
                  }
              },
              state: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              summary: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              title: {
                  type: 'string',
                  fields: {
                      raw: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              },
              video: {
                  properties: {
                      id: {
                          type: 'string',
                          index: 'not_analyzed'
                      },
                      thumbnail: {
                          type: 'string',
                          index: 'not_analyzed'
                      },
                      url: {
                          type: 'string',
                          index: 'not_analyzed'
                      }
                  }
              }
          }
      }
  }
end

def populate
  if CLIENT.indices.exists? index: 'videos'
    CLIENT.indices.delete index: 'videos'
  end

  CLIENT.indices.create index: 'videos'

  mapping

  cache = File.read('data.json')

  events = JSON.parse(cache)

  process_events(events['sessions'])
end
