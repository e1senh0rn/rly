module FixtureHelpers
  def file_fixture(fixture_name)
    base = RSpec.configuration.file_fixture_path
    path = Pathname.new(File.join(base, fixture_name))

    File.read(path)
  end
end
