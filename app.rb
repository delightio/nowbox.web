Aji::APP = Rack::Builder.app do

  use Rack::Exceptional, Aji.conf['EXCEPTIONAL_API_KEY'] if
  Aji::RACK_ENV == 'production'

  use Rack::Deflater
  use Rack::Session::Cookie
  use OmniAuth::Builder do
    provider :twitter, Aji.conf['CONSUMER_KEY'], Aji.conf['CONSUMER_SECRET']
    provider :facebook, Aji.conf['APP_ID'], Aji.conf['APP_SECRET'],
      { :scope => 'email,read_stream,publish_stream,offline_access',
        :display => :touch }
    provider :you_tube, Aji.conf['YOUTUBE_OA_KEY'],
      Aji.conf['YOUTUBE_OA_SECRET']
    # TODO: Do want: Diaspora* integration... somehow.. someway.
  end

  map "http://#{Aji.conf['TLD']}/" do
    run Aji::Viewer
  end

  map "http://mailer.#{Aji.conf['TLD']}/" do
    run Aji::Mailer
  end unless Aji::RACK_ENV == 'production'

  map '/auth' do
    run Aji::AuthController
  end

  map "http://resque.#{Aji.conf['TLD']}/" do
    use Rack::Auth::Basic do |username, password|
      [ username, password ] == [ "resque", "mellon" ]
    end

    run Resque::Server
  end

  map "http://api.#{Aji.conf['TLD']}/" do
    run Aji::API
  end

  map "http://api.#{Aji.conf['TLD']}/google90a33d3762d05419.html" do
    run GoogleAuth
  end

  map "http://api.#{Aji.conf['TLD']}/loadstorm-34094.html" do
    run LoadAuth
  end

  map "http://apidoc.#{Aji.conf['TLD']}/" do
    use Rack::Auth::Basic do |username, password|
      [ username, password ] == [ "apidoc", "water" ]
    end

    use Rack::Static, :urls => { '/' => 'aji.html' }, :root => 'docs'
    run Rack::Directory.new('docs')
  end
end

