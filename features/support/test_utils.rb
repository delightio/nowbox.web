module TestUtils
  def dump_response_on_failure
    yield
  rescue
    puts last_response.inspect
    raise
  end

  def json_body response
    MultiJson.decode response.body
  end


end
