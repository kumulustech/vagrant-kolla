# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

# Require a recent version of vagrant otherwise some have reported errors setting host names on boxes
Vagrant.require_version ">= 1.7.4"

# The number of nodes to provision
$num_node = (ENV['NUM_NODES'] || 1).to_i

# ip configuration
$control_ip = ENV['CONTROL_IP'] || "192.168.56.10"
$control_alt_ip = ENV['CONTROL_ALT_IP'] || "192.168.57.10"
$node_ip_base = ENV['NODE_IP_BASE'] || "192.168.56."
$node_ip_alt_base = ENV['NODE_IP_ALT_BASE'] || "192.168.57."
$node_ips = $num_node.times.collect { |n| $node_ip_base + "#{n+20}" }
$node_alt_ips = $num_node.times.collect { |n| $node_ip_alt_base + "#{n+20}" }

# Determine whether vagrant should use nfs to sync folders
$use_nfs = ENV['VAGRANT_USE_NFS'] == 'true'
# Determine whether vagrant should use rsync to sync folders
$use_rsync = ENV['VAGRANT_USE_RSYNC'] == 'true'

# define the OS to use
$os = 'ubuntu'
# Default OS platform to provider/box information
$provider_boxes = {
  :virtualbox => {
    'ubuntu' => {
      :box_name => 'ubuntu/xenial64',
      #:box_url => 'https://www.dropbox.com/s/z8rb65j7w5ym820/dual-xenial.box?dl=1',
    }
  },
  :libvirt => {
    'ubuntu' => {
      :box_name => 'ubuntu/xenial64',
    }
  },
}

host = RbConfig::CONFIG['host_os']
if host =~ /darwin/
  $vm_cpus = `sysctl -n hw.physicalcpu`.to_i
elsif host =~ /linux/
  $vm_cpus = `cat /proc/cpuinfo | grep 'core id' | sort -u | wc -l`.to_i
  if $vm_cpus < 1
      $vm_cpus = `nproc`.to_i
  end
else #  windows?
  $vm_cpus = 2
end

# Give VM 1024MB of RAM by default
$vm_control_mem = (ENV['CONTRL_MEMORY'] || 8192).to_i
$vm_node_mem = (ENV['NODE_MEMORY'] || 4096).to_i

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  if Vagrant.has_plugin?("vagrant-proxyconf")
    $http_proxy = ENV['HTTP_PROXY'] || ""
    $https_proxy = ENV['HTTPS_PROXY'] || ""
    $no_proxy = ENV['NO_PROXY'] || "127.0.0.1"
    config.proxy.http     = $http_proxy
    config.proxy.https    = $https_proxy
    config.proxy.no_proxy = $no_proxy
  end

  # this corrects a bug in 1.8.5 where an invalid SSH key is inserted.
  if Vagrant::VERSION == "1.8.5"
    config.ssh.insert_key = false
  end

  def setvmboxandurl(config, provider)
    if ENV['BOX_NAME'] then
      config.vm.box = ENV['BOX_NAME']

      if ENV['BOX_URL'] then
        config.vm.box_url = ENV['BOX_URL']
      end

      if ENV['BOX_VERSION'] then
        config.vm.box_version = ENV['BOX_VERSION']
      end
    else
      config.vm.box = $provider_boxes[provider][$os][:box_name]

      if $provider_boxes[provider][$os][:box_url] then
        config.vm.box_url = $provider_boxes[provider][$os][:box_url]
      end

      if $provider_boxes[provider][$os][:box_version] then
        config.vm.box_version = $provider_boxes[provider][$os][:box_version]
      end
    end
  end

  def customize_vm(config, vm_mem, vm_name)

    if $use_nfs then
      config.vm.synced_folder ".", "/vagrant", nfs: true
    elsif $use_rsync then
      opts = {}
      if ENV['VAGRANT_RSYNC_ARGS'] then
        opts[:rsync__args] = ENV['VAGRANT_RSYNC_ARGS'].split(" ")
      end
      if ENV['VAGRANT_RSYNC_EXCLUDE'] then
        opts[:rsync__exclude] = ENV['VAGRANT_RSYNC_EXCLUDE'].split(" ")
      end
      config.vm.synced_folder ".", "/vagrant", opts
    end

    # Don't attempt to update Virtualbox Guest Additions (requires gcc)
    if Vagrant.has_plugin?("vagrant-vbguest") then
      config.vbguest.auto_update = false
    end
    # Finally, fall back to VirtualBox
    config.vm.provider :virtualbox do |v, override|
      setvmboxandurl(override, :virtualbox)
      v.memory = vm_mem # v.customize ["modifyvm", :id, "--memory", vm_mem]
      v.cpus = $vm_cpus # v.customize ["modifyvm", :id, "--cpus", $vm_cpus]

      # Use faster paravirtualized networking
      v.customize ["modifyvm", :id, "--nictype1", "virtio"]
      v.customize ["modifyvm", :id, "--nictype2", "virtio"]
      v.customize ["modifyvm", :id, "--nictype3", "virtio"]
      # unless File.exist?("#{vm_name}.vdi")
      #   v.customize ['createhd', '--filename', "#{vm_name}.vdi", '--variant', 'Fixed', '--size', 20 * 1024]
      # end
      # v.customize ['storageattach', :id,  '--storagectl', 'SCSI', '--port', 1, '--device', 0, '--type', 'hdd', '--medium', "#{vm_name}.vdi"]
    end
  end

  # Kubernetes control
  config.vm.define 'control' do |c|
    customize_vm c, $vm_control_mem, 'control'
    #c.vm.provision "shell", run: "once", path: "control-ubuntu.sh"
    c.vm.hostname = 'control'
    c.vm.network "private_network", ip: "#{$control_ip}"
    c.vm.network "private_network", ip: "#{$control_alt_ip}"
#    c.vm.network "public_network", auto_config: false
  end

  # Kubernetes node
  $num_node.times do |n|
    node_vm_name = "node-#{n+1}"

    config.vm.define node_vm_name do |node|
      customize_vm node, $vm_node_mem, node_vm_name

      node_ip = $node_ips[n]
      node_alt_ip = $node_alt_ips[n]
      #node.vm.provision "shell", run: "once", path: "node-ubuntu.sh"
      node.vm.hostname = "node-#{n+1}"
      node.vm.network "private_network", ip: "#{node_ip}"
      node.vm.network "private_network", ip: "#{node_alt_ip}"
      if "#{n}" == "#{$num_node.to_i-1}"
        config.vm.provision "ansible" do |a|
          a.playbook = "configure_baseline.yml"
          a.limit = "all"
        end
      end
    end
  end
end
