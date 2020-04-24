ENV["RACK_ENV"] = "test"

require "minitest/autorun"
require "rack/test"
require "fileutils"

require_relative "../cms"

class CmsTest < Minitest::Test
  include Rack::Test::Methods

  def setup
    FileUtils.mkdir_p(data_path)
  end

  def teardown
    FileUtils.rm_rf(data_path)
  end

  def create_document(name, content = "")
    File.open(File.join(data_path, name), "w") do |file|
      file.write(content)
    end
  end

  def app
    Sinatra::Application
  end

  def test_index
    create_document "about.md"
    create_document "changes.txt"
    create_document "history.txt"

    get "/"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body.encode("UTF-8"), "about.md"
    assert_includes last_response.body.encode("UTF-8"), "changes.txt"
    assert_includes last_response.body.encode("UTF-8"), "history.txt"
  end

  def test_viewing_history_document
    create_document "history.txt", "1993 - Yukihiro Matsumoto dreams up Ruby."

    get "/history.txt"

    assert_equal 200, last_response.status
    assert_equal "text/plain", last_response["Content-Type"]
    assert_includes last_response.body.encode("UTF-8"), "1993 - Yukihiro Matsumoto dreams up Ruby."
  end

  def test_viewing_markdown_document
    create_document "about.md", "# Ruby is..." 

    get "/about.md"

    assert_equal 200, last_response.status
    assert_equal "text/html;charset=utf-8", last_response["Content-Type"]
    assert_includes last_response.body.encode("UTF-8"), "<h1>Ruby is...</h1>"
  end

  def test_not_found
    # get a file that doesn't exist
    get "/doesnotexist.txt"
   
    # verify app redirects user
    assert_equal 302, last_response.status

    # request page user was redirected to
    get last_response["location"]

    # check page loaded correctly and displays error message
    assert_equal 200, last_response.status
    assert_includes last_response.body.encode("UTF-8"), "doesnotexist.txt does not exist."

    # check that error message disappears on reload of page
    get "/"
    refute_includes last_response.body.encode("UTF-8"), "The specified file was not found."
  end

  def test_editing_document
    create_document "changes.txt"
    
    get "/changes.txt/edit"

    assert_equal 200, last_response.status
    assert_includes last_response.body.encode("UTF-8"), "<textarea"
    assert_includes last_response.body.encode("UTF-8"), %q(<button type="submit")
  end

  def test_updating_document
    post "/changes.txt", content: "new content"

    assert_equal 302, last_response.status

    get last_response["location"]

    assert_includes last_response.body.encode("UTF-8"), "changes.txt has been updated."

    get "/changes.txt"
    assert_equal 200, last_response.status
    assert_includes last_response.body.encode("UTF-8"), "new content"
  end

  def test_view_new_document_form
    get "/new"

    assert_equal 200, last_response.status
    assert_includes last_response.body.encode("UTF-8"), "<input"
    assert_includes last_response.body.encode("UTF-8"), '<input type="submit"'
  end

  def test_create_new_document
    post "/create", document_name: "test.txt"
    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body.encode("UTF-8"), "test.txt was created."

    get "/"
    assert_includes last_response.body.encode("UTF-8"), "test.txt"
  end

  def test_creating_document_without_name
    post "/create", document_name: ""
    assert_equal 422, last_response.status
    assert_includes last_response.body.encode("UTF-8"), "A name is required"
  end

  def test_validating_existing_document_name
    create_document "test.txt"

    post "/create", document_name: "test.txt"
    assert_equal 422, last_response.status
    assert_includes last_response.body.encode("UTF-8"), 'File name already exists.'
  end

  def test_deleting_documnet
    create_document("test.txt")

    post "/test.txt/delete"

    assert_equal 302, last_response.status

    get last_response["Location"]
    assert_includes last_response.body, "test.txt has been deleted."

    get "/"
    refute_includes last_response.body, "test.txt"
  end
end
