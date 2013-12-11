root_dirs = [
  node['zabbix']['agent']['include_dir']
]

# Create root folders
root_dirs.each do |dir|
  directory dir do
    unless node['platform'] == "windows"
      owner "root"
      group node['root_group']
      mode "755" 
    end
    recursive true
    notifies :restart, "service[zabbix_agentd]"
  end
end
