require 'fog'
require 'pp'

# Connect and authenticate
#
conn = Fog::Compute.new({
  :provider => 'OpenStack',
  :openstack_api_key => "changeme",
  :openstack_username => "admin@foobar.net",
  :openstack_auth_url => "http://osfoobar.net:5000/v2.0/tokens"
})

# Destroy all the servers matching foobar-*
#
conn.servers.each do |s| 
  if s.name =~ /^foobar-.*/
    puts "Destroying server #{s.name}"
    s.destroy 
  end
end
