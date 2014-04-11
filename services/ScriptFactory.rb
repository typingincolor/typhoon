require 'erb'
require 'tilt'
require 'mongo'

include Mongo

class ScriptFactory
  def initialize
    @@db = MongoClient.new('localhost').db('script_engine')
  end

  def build request
    if request['action'] == 'send_email'
      template = Tilt::ERBTemplate.new('views/email_script.erb')
      script = template.render self, request['data']
    else
      raise 'unknown action'
    end

    # store the script
    coll = @@db.collection 'scripts'
    document = JSON.parse script
    coll.insert document
  end

  def get id
    coll = @@db.collection 'scripts'
    document = coll.find('_id' => BSON::ObjectId(id)).to_a
    document[0].to_json
  end
end
