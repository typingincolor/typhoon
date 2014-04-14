require 'data_mapper'

class Task
  include DataMapper::Resource
  property :id, Serial
  property :url, String, :required => true
  property :at, DateTime, :required => true
  property :code, Integer
  property :result, Integer
  property :completed_at, DateTime
end
