# directories to watch
directories %w(lib test) \
    .select{|d| Dir.exist?(d) ? d : UI.warning("Directory #{d} does not exist")}


# guard 'rake', :task => 'build' do
#   watch(%r{^my_file.rb})
# end

guard :minitest, include: ['lib'] do
  # with Minitest::Unit
  watch(%r{^test/(.*)\/?test_(.*)\.rb$})
  watch(%r{^lib/(.*/)?([^/]+)\.rb$})     { |m| "test/#{m[1]}test_#{m[2]}.rb" }
  watch(%r{^test/test_helper\.rb$})      { 'test' }

  # with Minitest::Spec
  # watch(%r{^spec/(.*)_spec\.rb$})
  # watch(%r{^lib/(.+)\.rb$})         { |m| "spec/#{m[1]}_spec.rb" }
  # watch(%r{^spec/spec_helper\.rb$}) { 'spec' }
end
