require_relative "../test_helper"

module Unit
  class TestVersion < MiniTest::Test

    describe VPS::VERSION do
      it "has the current version" do
        version = File.read(path("VERSION")).strip
        assert_equal version, VPS::VERSION
        assert File.read(path "CHANGELOG.md").include?("Version #{version} ")
      end
    end

  end
end
