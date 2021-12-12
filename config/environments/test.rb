puts "Loading testing environment"

# Add environment-specific configuration here. E.g.:
#
# Service.config.foo = "bar"

# Enable SQL debugging to stdout
ActiveRecord::Base.logger = Logger.new(STDOUT)
