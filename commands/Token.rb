class Token
  attr_reader :headers, :body

  def initialize(body: '', headers: [])
    @headers = headers
    @body = body
  end

  def add_header(header:, value:)
    @headers << { header: header, value: value }
    self
  end

  def set_body(body)
    @body = body
    self
  end

  def get_body
    @body
  end

  def get
    { headers: @headers, body: @body }
  end

  def to_json(*_args)
    get.to_json
  end
end
