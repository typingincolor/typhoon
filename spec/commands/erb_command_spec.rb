require_relative '../spec_helper'
require_relative '../../commands/init'

RSpec.describe ErbCommand do
  describe 'security' do
    it 'prevents path traversal attacks' do
      command = {
        'command' => 'erb',
        'data' => {
          'template' => '../../etc/passwd',
          'template_data' => {}
        }
      }

      expect { ErbCommand.new(command) }.to raise_error(Typhoon::ValidationError, /not allowed/)
    end

    it 'prevents relative path attacks' do
      command = {
        'command' => 'erb',
        'data' => {
          'template' => '../config/database',
          'template_data' => {}
        }
      }

      expect { ErbCommand.new(command) }.to raise_error(Typhoon::ValidationError, /not allowed/)
    end

    it 'only allows whitelisted templates' do
      allowed_templates = ErbCommand::ALLOWED_TEMPLATES

      allowed_templates.each do |template_name|
        command = {
          'command' => 'erb',
          'data' => {
            'template' => template_name,
            'template_data' => {}
          }
        }

        expect { ErbCommand.new(command) }.not_to raise_error
      end
    end

    it 'lists allowed templates in error message' do
      command = {
        'command' => 'erb',
        'data' => {
          'template' => 'malicious',
          'template_data' => {}
        }
      }

      expect { ErbCommand.new(command) }.to raise_error(
        Typhoon::ValidationError,
        /Allowed templates: #{ErbCommand::ALLOWED_TEMPLATES.join(', ')}/
      )
    end
  end

  describe 'validation' do
    it 'requires template field' do
      command = {
        'command' => 'erb',
        'data' => { 'template_data' => {} }
      }

      expect { ErbCommand.new(command) }.to raise_error(Typhoon::ValidationError, /template/)
    end

    it 'requires template_data field' do
      command = {
        'command' => 'erb',
        'data' => { 'template' => 'email' }
      }

      expect { ErbCommand.new(command) }.to raise_error(Typhoon::ValidationError, /template_data/)
    end
  end

  describe '#execute' do
    before do
      # Create a test template
      FileUtils.mkdir_p('views') unless Dir.exist?('views')
      File.write('views/email.erb', 'Hello <%= name %>')
    end

    after do
      File.delete('views/email.erb') if File.exist?('views/email.erb')
    end

    it 'renders ERB template with data' do
      command = {
        'command' => 'erb',
        'data' => {
          'template' => 'email',
          'template_data' => { 'name' => 'World' }
        }
      }

      cmd = ErbCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.get_body).to eq('Hello World')
    end

    it 'adds header to token' do
      command = {
        'command' => 'erb',
        'data' => {
          'template' => 'email',
          'template_data' => { 'name' => 'Test' }
        }
      }

      cmd = ErbCommand.new(command)
      token = Token.new

      result = cmd.execute(token)

      expect(result.headers).to include(hash_including(header: 'ErbCommand', value: 'OK'))
    end

    it 'raises error if template file does not exist' do
      # Remove the template file
      File.delete('views/email.erb')

      command = {
        'command' => 'erb',
        'data' => {
          'template' => 'email',
          'template_data' => {}
        }
      }

      cmd = ErbCommand.new(command)
      token = Token.new

      expect { cmd.execute(token) }.to raise_error(Typhoon::ValidationError, /Invalid template path/)
    end
  end
end
