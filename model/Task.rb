require 'data_mapper'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/development.sqlite")

class Task
  include DataMapper::Resource
  property :id, Serial
  property :url, String, :required => true
  property :at, DateTime, :required => true
  property :completed_at, DateTime
end
DataMapper.finalize
