require_relative '../spec_helper'
require_relative '../../commands/init'

RSpec.describe EmailCommand do
  before do
    # Configure mail delivery for tests
    Mail.defaults do
      delivery_method :test
    end
    Mail::TestMailer.deliveries.clear
  end

  describe 'initialization' do
    it 'creates command with valid email and subject' do
      command = {
        'command' => 'email',
        'data' => {
          'to' => 'test@example.com',
          'subject' => 'Test Subject'
        }
      }

      expect { EmailCommand.new(command) }.not_to raise_error
    end

    it 'requires to field' do
      command = {
        'command' => 'email',
        'data' => { 'subject' => 'Test' }
      }

      expect { EmailCommand.new(command) }.to raise_error(Typhoon::ValidationError, /to/)
    end

    it 'requires subject field' do
      command = {
        'command' => 'email',
        'data' => { 'to' => 'test@example.com' }
      }

      expect { EmailCommand.new(command) }.to raise_error(Typhoon::ValidationError, /subject/)
    end
  end

  describe 'email validation' do
    it 'accepts valid email addresses' do
      valid_emails = [
        'user@example.com',
        'user.name@example.com',
        'user+tag@example.com',
        'user_name@example.co.uk',
        'user123@test-domain.com'
      ]

      valid_emails.each do |email|
        command = {
          'command' => 'email',
          'data' => { 'to' => email, 'subject' => 'Test' }
        }

        expect { EmailCommand.new(command) }.not_to raise_error, "Expected #{email} to be valid"
      end
    end

    it 'rejects invalid email addresses' do
      invalid_emails = [
        'not-an-email',
        '@example.com',
        'user@',
        'user @example.com',
        'user@example',
        'user@.com',
        'user..name@example.com',
        ''
      ]

      invalid_emails.each do |email|
        command = {
          'command' => 'email',
          'data' => { 'to' => email, 'subject' => 'Test' }
        }

        expect { EmailCommand.new(command) }.to raise_error(Typhoon::ValidationError, /Invalid email address/),
          "Expected #{email.inspect} to be invalid"
      end
    end

    it 'includes invalid email in error message' do
      command = {
        'command' => 'email',
        'data' => { 'to' => 'invalid@@@email', 'subject' => 'Test' }
      }

      expect { EmailCommand.new(command) }.to raise_error(Typhoon::ValidationError, /invalid@@@email/)
    end
  end

  describe '#execute' do
    let(:command_data) do
      {
        'command' => 'email',
        'data' => {
          'to' => 'recipient@example.com',
          'subject' => 'Test Email'
        }
      }
    end

    it 'sends an email with token body' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Email body content')

      cmd.execute(token)

      expect(Mail::TestMailer.deliveries.length).to eq(1)
      email = Mail::TestMailer.deliveries.first
      expect(email.to).to eq(['recipient@example.com'])
      expect(email.subject).to eq('Test Email')
      expect(email.body.to_s).to eq('Email body content')
    end

    it 'uses configured from address' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Test')

      cmd.execute(token)

      email = Mail::TestMailer.deliveries.first
      expect(email.from).not_to be_empty
    end

    it 'adds header to token' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Test')

      result = cmd.execute(token)

      expect(result.headers).to include(hash_including(header: 'EmailCommand', value: 'OK'))
    end

    it 'sets token body to email string representation' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Original body')

      result = cmd.execute(token)

      expect(result.get_body).to include('Test Email')
      expect(result.get_body).to include('recipient@example.com')
    end

    it 'returns the token' do
      cmd = EmailCommand.new(command_data)
      token = Token.new

      result = cmd.execute(token)

      expect(result).to be(token)
    end

    it 'sends email with empty body if token is empty' do
      cmd = EmailCommand.new(command_data)
      token = Token.new

      cmd.execute(token)

      email = Mail::TestMailer.deliveries.first
      expect(email.body.to_s).to eq('')
    end

    it 'handles special characters in subject' do
      command = {
        'command' => 'email',
        'data' => {
          'to' => 'test@example.com',
          'subject' => 'Test: Special & Characters <>'
        }
      }
      cmd = EmailCommand.new(command)
      token = Token.new(body: 'Body')

      cmd.execute(token)

      email = Mail::TestMailer.deliveries.first
      expect(email.subject).to eq('Test: Special & Characters <>')
    end

    it 'handles unicode in body' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Hello 世界 🌍')

      cmd.execute(token)

      email = Mail::TestMailer.deliveries.first
      expect(email.body.to_s).to include('世界')
      expect(email.body.to_s).to include('🌍')
    end
  end

  describe 'error handling' do
    let(:command_data) do
      {
        'command' => 'email',
        'data' => {
          'to' => 'test@example.com',
          'subject' => 'Test'
        }
      }
    end

    it 'raises StandardError when email delivery fails' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Test')

      # Simulate delivery failure
      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_raise(StandardError, 'SMTP error')

      expect { cmd.execute(token) }.to raise_error(StandardError, /Email delivery failed/)
    end

    it 'includes original error message in raised error' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Test')

      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_raise(StandardError, 'Connection timeout')

      expect { cmd.execute(token) }.to raise_error(StandardError, /Connection timeout/)
    end

    it 'logs error before raising' do
      cmd = EmailCommand.new(command_data)
      token = Token.new(body: 'Test')

      allow_any_instance_of(Mail::Message).to receive(:deliver!).and_raise(StandardError, 'Test error')
      expect(LOGGER).to receive(:error).with(/Failed to send email/)

      expect { cmd.execute(token) }.to raise_error(StandardError)
    end
  end

  describe 'email configuration' do
    it 'loads email config from Config' do
      cmd_data = {
        'command' => 'email',
        'data' => { 'to' => 'test@example.com', 'subject' => 'Test' }
      }
      cmd = EmailCommand.new(cmd_data)
      token = Token.new(body: 'Test')

      # Access the private email_config method
      config = cmd.send(:email_config)

      expect(config).to have_key(:from)
    end

    it 'caches email config' do
      cmd_data = {
        'command' => 'email',
        'data' => { 'to' => 'test@example.com', 'subject' => 'Test' }
      }
      cmd = EmailCommand.new(cmd_data)

      # Call twice to test caching
      config1 = cmd.send(:email_config)
      config2 = cmd.send(:email_config)

      expect(config1).to be(config2)
    end
  end

  describe 'integration' do
    it 'can be used in a command chain' do
      cmd_data = {
        'command' => 'email',
        'data' => {
          'to' => 'test@example.com',
          'subject' => 'Chained Email'
        }
      }
      cmd = EmailCommand.new(cmd_data)

      token = Token.new
        .set_body('Initial body')
        .add_header(header: 'Previous', value: 'Command')

      result = cmd.execute(token)

      expect(result.headers.length).to eq(2)
      expect(Mail::TestMailer.deliveries.length).to eq(1)
    end
  end
end
