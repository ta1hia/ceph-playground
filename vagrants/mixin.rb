# This is the vagrant mixin
# By including it with the line below (see double hashes), we guarantee that our
# vagrant infrastructure shares the same characteristics

## eval(IO.read("../vagrant.mixin"), binding)

require 'yaml'

if File.exist?("../config.yaml")
   data = YAML.load_file("../config.yaml")
end

ip = data['hosts'][config.vm.hostname]

config.vm.box_url = data['vagrants'][config.vm.box]
config.vm.network "private_network", :ip => ip
config.vm.provision "shell", inline: "echo #{ip} > /etc/publicip"

# home directory mounting in a vagrant
config.vm.provider :virtualbox do |provider, override|
  if defined?(mount_repo) then
    config.vm.synced_folder "../../../#{mount_repo}", "/data/#{mount_repo}"
  end
end

# run ansible against the box
config.vm.provision "ansible" do |ansible|

  if defined?(playbook) then
    ansible.playbook = "../../playbooks/#{playbook}.yaml"
  end

  # ansible vault key file
  ansible_keyfile = "../../playbooks/ansible.vault.key"
  if File.exist?(ansible_keyfile) then
    ansible.vault_password_file = ansible_keyfile
  end

  ENV['ANSIBLE_CONFIG'] = "../../playbooks/ansible.cfg"
  if ENV['DEBUG'] != nil then
    ansible.verbose = 'vv'
  end
  if ENV['ANSIBLE_TAGS'] != nil then
    ansible.tags = ENV['ANSIBLE_TAGS']
  end
  if ENV['ANSIBLE_START_TASK'] != nil then
    ansible.start_at_task = ENV['ANSIBLE_START_TASK']
  end

  # ansible variables specifically set when vagranting!
  if defined?(ansible_extras) then
    ansible.extra_vars = ansible_extras
  end
end
