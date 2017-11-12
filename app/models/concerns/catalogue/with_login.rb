module Catalogue::WithLogin
  private

  def login(url)
    full_url = "#{supplier.host}#{url}"
    query = {
      'AUTH_FORM' => 'Y',
      'TYPE' => 'AUTH',
      'backurl' => '/auth/',
      'USER_LOGIN' => 'beznatsenki@yandex.ru',
      'USER_PASSWORD' =>  'Q1w2E3r4',
      'USER_REMEMBER' => 'Y'
    }
    response = HTTParty.post full_url, query: query
    byebug
  end

  def headers
    @headers
  end
end
