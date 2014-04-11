class Token
  def initialize
    @token = {:headers => [], :body => ""}
  end

  def add_header header
    puts header[:header]
    puts header[:value]
    puts @token
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
