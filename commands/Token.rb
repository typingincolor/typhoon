class Token
  def initialize
    @token = {:headers => [], :body => ''}
  end

  def add_header header
    @token[:headers].push header
  end

  def set_body body
    @token[:body] = body
  end

  def get_body
    @token[:body]
  end

  def get
    @token
  end
end
