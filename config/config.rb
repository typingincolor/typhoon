require 'yaml'
require 'erb'

module Config
  class << self
    attr_reader :settings

    def load!(env = ENV['RACK_ENV'] || 'development')
      config_file = File.join(__dir__, 'settings.yml')
      erb_content = ERB.new(File.read(config_file)).result
      all_settings = YAML.safe_load(erb_content, permitted_classes: [], aliases: true)

      @settings = deep_symbolize_keys(all_settings[env])
      @settings[:env] = env
      @settings
    end

    # Explicit accessor methods for configuration sections
    # Replaces method_missing anti-pattern for better IDE support and type safety

    def app
      settings[:app]
    end

    def email
      settings[:email]
    end

    def database
      settings[:database]
    end

    def moneta
      settings[:moneta]
    end

    def env
      settings[:env]
    end

    # Hash-like access for dynamic cases
    def [](key)
      settings[key]
    end

    private

    def deep_symbolize_keys(hash)
      return hash unless hash.is_a?(Hash)

      hash.each_with_object({}) do |(key, value), result|
        result[key.to_sym] = value.is_a?(Hash) ? deep_symbolize_keys(value) : value
      end
    end
  end
end

Config.load!
