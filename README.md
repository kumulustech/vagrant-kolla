# Launching Kolla based OpenStack

As with any installation, there are certain pre-requisites that need to be in place.  For simple "devstack" like usage, we can pull our images from the Hub.docker.io registry, and simply leverage/extend the default kolla driven ansible inventory to manage deployment.

The following lab is based on the kolla-packet project:

    git clone https://github.com/kumulustech/kolla-packet
    cd kolla-packet

1) if you're going to use bare metal servers, install Ubuntu, and either add their IP addresses to DNS, or update the default inventory file with their IP addresses.

If you are using an automated infrastructure, specifically packet.net for compute and dnsimple.com as a managed DNS service, you can use the packet-deploy.yml Ansible playbook. If not, you may be able to do a similar deployment with a tool like terraform or even write your own ansible to launch your infastructure.

2) If you're going to use packet.net as your target, get a packet project ID and create (or capture) your via the app.packet.net site.
3) Create a "~/dev/packet.api" file (it can be any name), and in it create a line like (replacing the packet-auth-token-from... string with the token you grabbed from app.packet.net and the project id with the project id from the URL or the project info page)

    PACKET_API_TOKEN=packet-auth-token-from-app-packet-net
    PACKET_PROJECT=packet-project-from-app-packet-net

Then source that file:

    source ~/dev/packet.api

3) We also need the packet service, and ansible available to us, so create a virtual environment (or spin up a container) and install the parameters.

    mkdir ~/.pyenv
    pip install virtualenv
    virtualenv ~/.pyenv/kolla
    . ~/.pyenv/kolla/bin/activate
    pip install -r requirements.txt

4) If you start a new terminal at any time don't forget to source the virtual environment activate script:

     . ~/.pyenv/kolla/bin/active

And source your packet.api file as well to have the right environment variables.

     . ~/dev/packet.api

5) If you have a DNSimple account, and want to use the full current script, get an API token, and your DNSimple account ID and add them as "DNSIMPLE_TOKEN" and "DNSIMPLE_ACCOUNT" to your packet.api file:

    PACKET_API_TOKEN=packet-auth-token-from-app-packet-net
    PACKET_PROJECT=packet-project-from-app-packet-net
    DNSIMPLE_TOKEN=dnsimple-api-token
    DNSIMPLE_ACCOUNT=dnsimple-account-id

Source the packet.api file again:

    . ~/dev/packet.api

6) Finally we can launch, either with DNSimple to set the DNS parameters:

    ./create-dnsimple-packet.sh

Or if you don't have the DNSimple service, you can run:

    ./create.sh

Note, once you're done, you can clean up your environment with the "delete" version of the above scripts. Note that cleanup can only happen _after_ the packet nodes have finished their boot process, which usually takes ~ 5 minutes.  State can be seen on app.packet.net as well.

6) If you used either of the packet based systems, you will have an inventory with ssh host definitions and IP addresses from the packet deployments.

7) Now look at the Kolla configuratinos in the globals.yml from the files/ directory.  Note that some parameters are auto-discovered from the debian-network.sh script, as we try to auto-discover the default host IP address for the API services and Horizon (if configured).

Finally, we can configure our nodes with the prerequisites to deploy Kolla/openstack (e.g. docker, ansible, kolla code, etc.):

    ansible-playbook -i inventory initialize.yml

When this is complete, you should have a running OpenStack service.  The control node will have a /root/open.rc resource file, and the default admin password for the "admin" user will be This!5@Password unless you set it to be different in the initialize.yml script.

## Network config
Because this was intended for setting up little test environments, the network config is fairly simplistic, including the scripted creation of a basic tenant/router/floating IP network.  The "public" services are associated with a linux bridge "external" bridge (ext), and an additional interface can readily be added if one is available for proper resource sharing.  In which case it would be sensible to look at the IP range set on the bridge (which allows controller access to the "external" network), along with the setup_network.sh script that configures the network and floating pool.
