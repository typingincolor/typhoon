require_relative '../spec_helper'
require_relative '../../config/logger'
require 'stringio'

RSpec.describe TyphoonLogger do
  describe '.create' do
    it 'creates a logger instance' do
      logger = TyphoonLogger.create

      expect(logger).to be_a(Logger)
    end

    it 'uses custom output if provided' do
      output = StringIO.new
      logger = TyphoonLogger.create(output)

      logger.info('test message')

      expect(output.string).to include('test message')
    end

    it 'defaults to stdout' do
      logger = TyphoonLogger.create

      expect(logger.instance_variable_get(:@logdev).dev).to eq($stdout)
    end

    it 'sets log level from environment' do
      ENV['LOG_LEVEL'] = 'DEBUG'
      logger = TyphoonLogger.create

      expect(logger.level).to eq(Logger::DEBUG)

      ENV.delete('LOG_LEVEL')
    end

    it 'defaults to INFO level' do
      ENV.delete('LOG_LEVEL')
      logger = TyphoonLogger.create

      expect(logger.level).to eq(Logger::INFO)
    end

    it 'uses JSONFormatter' do
      logger = TyphoonLogger.create

      expect(logger.formatter).to be_a(TyphoonLogger::JSONFormatter)
    end
  end

  describe TyphoonLogger::JSONFormatter do
    let(:output) { StringIO.new }
    let(:logger) do
      log = Logger.new(output)
      log.formatter = TyphoonLogger::JSONFormatter.new
      log
    end

    describe '#call' do
      it 'formats log as JSON' do
        logger.info('test message')

        json = JSON.parse(output.string)
        expect(json).to have_key('timestamp')
        expect(json).to have_key('severity')
        expect(json).to have_key('message')
      end

      it 'includes severity level' do
        logger.info('test')

        json = JSON.parse(output.string)
        expect(json['severity']).to eq('INFO')
      end

      it 'includes ISO8601 timestamp' do
        logger.info('test')

        json = JSON.parse(output.string)
        expect(json['timestamp']).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it 'includes message' do
        logger.info('test message')

        json = JSON.parse(output.string)
        expect(json['message']).to eq('test message')
      end

      it 'handles different severity levels' do
        logger.debug('debug msg')
        logger.info('info msg')
        logger.warn('warn msg')
        logger.error('error msg')

        lines = output.string.split("\n").reject(&:empty?)
        severities = lines.map { |line| JSON.parse(line)['severity'] }

        expect(severities).to include('DEBUG', 'INFO', 'WARN', 'ERROR')
      end

      it 'handles non-string messages' do
        logger.info({ key: 'value' })

        json = JSON.parse(output.string)
        expect(json['message']).to include('key')
      end

      it 'includes exception details for exceptions' do
        error = StandardError.new('test error')
        error.set_backtrace(['line1', 'line2', 'line3', 'line4', 'line5', 'line6'])

        logger.error(error)

        json = JSON.parse(output.string)
        expect(json['exception']).to be_a(Hash)
        expect(json['exception']['class']).to eq('StandardError')
        expect(json['exception']['message']).to eq('test error')
        expect(json['exception']['backtrace']).to be_an(Array)
      end

      it 'limits backtrace to 5 lines' do
        error = StandardError.new('test')
        error.set_backtrace((1..10).map { |i| "line#{i}" })

        logger.error(error)

        json = JSON.parse(output.string)
        expect(json['exception']['backtrace'].length).to eq(5)
      end

      it 'includes progname if provided' do
        logger = Logger.new(output)
        logger.formatter = TyphoonLogger::JSONFormatter.new
        logger.progname = 'TestApp'

        logger.info('test')

        json = JSON.parse(output.string)
        expect(json['progname']).to eq('TestApp')
      end

      it 'outputs each log as a single line' do
        logger.info('message 1')
        logger.info('message 2')

        lines = output.string.split("\n").reject(&:empty?)
        expect(lines.length).to eq(2)
      end

      it 'produces valid JSON for each line' do
        logger.info('test 1')
        logger.warn('test 2')
        logger.error('test 3')

        lines = output.string.split("\n").reject(&:empty?)
        lines.each do |line|
          expect { JSON.parse(line) }.not_to raise_error
        end
      end
    end
  end

  describe 'LOGGER constant' do
    it 'is defined globally' do
      expect(defined?(LOGGER)).to eq('constant')
      expect(LOGGER).to be_a(Logger)
    end

    it 'uses TyphoonLogger formatter' do
      expect(LOGGER.formatter).to be_a(TyphoonLogger::JSONFormatter)
    end
  end
end
