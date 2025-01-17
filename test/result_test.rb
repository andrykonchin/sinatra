require File.expand_path('helper', __dir__)

class ThirdPartyError < RuntimeError
  def http_status; 400 end
end

class ResultTest < Minitest::Test
  it "sets response.body when result is a String" do
    mock_app { get('/') { 'Hello World' } }

    get '/'
    assert ok?
    assert_equal 'Hello World', body
  end

  it "sets response.body when result is an Array of Strings" do
    mock_app { get('/') { ['Hello', 'World'] } }

    get '/'
    assert ok?
    assert_equal 'HelloWorld', body
  end

  it "sets response.body when result responds to #each" do
    mock_app do
      get('/') do
        res = lambda { 'Hello World' }
        def res.each ; yield call ; end
        return res
      end
    end

    get '/'
    assert ok?
    assert_equal 'Hello World', body
  end

  it "sets response.body to [] when result is nil" do
    mock_app { get( '/') { nil } }

    get '/'
    assert ok?
    assert_equal '', body
  end

  it "sets status, headers, and body when result is a Rack response tuple" do
    mock_app {
      get('/') { [203, {'Content-Type' => 'foo/bar'}, 'Hello World'] }
    }

    get '/'
    assert_equal 203, status
    assert_equal 'foo/bar', response['Content-Type']
    assert_equal 'Hello World', body
  end

  it "sets status and body when result is a two-tuple" do
    mock_app { get('/') { [409, 'formula of'] } }

    get '/'
    assert_equal 409, status
    assert_equal 'formula of', body
  end

  it "raises a ArgumentError when result is a non two or three tuple Array" do
    mock_app {
      get('/') { [409, 'formula of', 'something else', 'even more'] }
    }

    assert_raises(ArgumentError) { get '/' }
  end

  it "sets status when result is a Integer status code" do
    mock_app { get('/') { 205 } }

    get '/'
    assert_equal 205, status
    assert_equal '', body
  end

  it "sets status to 500 when raised error is not Sinatra::Error" do
    mock_app do
      set :raise_errors, false
      get('/') { raise ThirdPartyError }
    end

    get '/'
    assert_equal 500, status
    assert_equal '<h1>Internal Server Error</h1>', body
  end
end
