require 'test_helper'

class ExportControllerTest < ActionDispatch::IntegrationTest
  test "should get mappings" do
    get export_mappings_url
    assert_response :success
  end
end
