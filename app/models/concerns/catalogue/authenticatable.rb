module Catalogue::Authenticatable
  private

  def login(url, auth_query)
    return set_cookie(file_contents :session_cookie) unless obsolete? :session_cookie
    puts "Authenticating at #{url} ..."

    conn = Faraday.new do |connection|
      connection.request  :multipart
      connection.headers['Content-Type'] = 'multipart/form-data'
      # connection.response :logger
      connection.adapter  :net_http
    end

    response = conn.post "#{supplier.host}#{url}", auth_query
    raw_cookies = response.headers['set-cookie']

    return auth_failed unless raw_cookies.present?

    cookies = cookies_as_set raw_cookies

    set_cookie cookies
    store_cookie cookies

    puts "Successfully authenticatied ✅"
  end

  def cookies_as_set(raw_cookies)
    raw_cookies.scan(/(?:\A|,\s)([\w_\-]+=[\w_\-]+)(?:\s|;)/).join '; '
  end

  def set_cookie(cookie)
    puts 'Setting authentication cookie ...'
    merge_request_headers! 'Cookie' => cookie
  end

  def store_cookie(cookie)
    File.open(path_to_file(:session_cookie), 'w') { |file| file.write cookie }
  end

  def auth_failed
    abort 'Unsuccessful authentication: No session cookie present.'
  end
end
