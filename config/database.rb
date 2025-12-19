require 'sequel'
require_relative 'config'
require_relative 'logger'

# Setup database connection
db_config = Config.database

# Check if this is a full connection string or just a database name
if db_config[:database] =~ /^[a-z]+:\/\//
  # Full connection string (e.g., "postgres://..." or "sqlite://...")
  DB = Sequel.connect(db_config[:database])
else
  # Just a database name, assume SQLite
  DB = Sequel.connect(adapter: 'sqlite', database: db_config[:database])
end

# Configure Sequel
DB.extension :date_arithmetic
DB.loggers << LOGGER if Config.env == 'development'

# Create tables if they don't exist
DB.create_table?(:tasks) do
  primary_key :id
  String :url, null: false
  DateTime :at, null: false
  Integer :code
  String :result
  DateTime :completed_at
  DateTime :created_at, null: false
  DateTime :updated_at, null: false

  index :at
  index :completed_at
end

# Require models after DB is setup
require_relative '../model/Task'
