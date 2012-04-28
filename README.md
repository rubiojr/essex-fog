# Getting started with Fog and OpenStack Essex 

Before we start, make sure you have Essex support in Fog.

Essex support has not been merged into Fog upstream so you'll need
a custom Fog build to work through the tutorial.

Get the custom gem build from http://rubiojr.frameos.org/fog-1.3.1-essex.gem or build fog
yourself from https://github.com/MorphGlobal/fog/tree/morph_merge.

Follow the merge here if you are interested:

https://github.com/fog/fog/issues/848

It's a good idea to have OpenStack clients installed to explore other commands.
You can install them in Ubuntu with the following command:

    sudo apt-get install python-novaclient glance-client python-keystoneclient

    
Let's get started

    require 'fog'
    
## Connect and authenticate

    conn = Fog::Compute.new({
      :provider => 'OpenStack',
      :openstack_api_key => "changeme",
      :openstack_username => "admin@myfoobar-stack.net",
      :openstack_auth_url => "http://auth.myfoobar-stack.net:5000/v2.0/tokens"
    })

**openstack_auth_url** is the URL of the Keystone authentication server in this case.

**openstack_api_key** is the password I use to login to the dashboard (Horizon) and use the API.

    
## Find the server flavor we want.

m1.tiny has 512 MB of RAM and no additional ephemeral storage

List the flavors available with the command 'nova flavor-list'

    flavor = conn.flavors.find { |f| f.name == 'm1.tiny' }
    
## Find the server image/template we want

List the images available with 'nova image-list' or glance index

    image = conn.images.find { |i| i.name == 'ubuntu-precise-amd64' }
    
## Create the server

    server = conn.servers.create :name => "fooserver-#{Time.now.strftime '%Y%m%d'}",
                                 :image_ref => image.id,
                                 :flavor_ref => flavor.id,
                                 :key_name => 'my-foo-keypair' # optional

This will create the server asynchronously, since waiting for server.ready? is optional.

key_name is optional and is used to inject the specified keypair 
to the instance if cloud-init is present. You can then login via SSH without
password, among other things (https://help.ubuntu.com/community/CloudInit)

List currently available keypairs with 'nova keypair-list'
    
Wait for the server to be ready (optional, wait for state == 'ACTIVE')

    server.wait_for { ready? }
    
You can also check the status of the server with 'nova list':
    

    +--------------------------------------+-----------------+--------+-------------------+
    |                  ID                  |       Name      | Status |      Networks     |
    +--------------------------------------+-----------------+--------+-------------------+
    | e56b9306-063a-4622-89cb-b5069f805221 | foobar-20120428 | BUILD  | private=1.2.3.4   |
    +--------------------------------------+-----------------+--------+-------------------+
    
## List the servers running

    conn.servers.each do |s|
      puts s.name # server name
      puts s.state
      puts s.id
    end
    
## Associate a public IP to the server

Create if there are no floating ips available

If we find a free ip, not used by any instance, use that.

    ip = conn.addresses.find { |ip| ip.instance_id.nil? }
    
Otherwise create it

    if ip.nil?
      puts 'Creating IP...'
      ip = conn.addresses.create
    end
    
Associate the IP address to the server

    ip.server = server
    
## Cleanup or regret it, @geemus dixit

    ip.destroy
    server.destroy
