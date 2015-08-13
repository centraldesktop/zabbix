# Author:: Nacer Laradji (<nacer.laradji@gmail.com>)
# Cookbook Name:: zabbix
# Recipe:: web
#
# Copyright 2011, Efactures
#
# Apache 2.0
#

include_recipe "zabbix::common"

directory node['zabbix']['install_dir'] do
  mode "0755"
end

node.normal['zabbix']['web']['fqdn'] = node['fqdn'] if node['zabbix']['web']['fqdn'].nil?
unless node['zabbix']['web']['user']
  node.normal['zabbix']['web']['user'] = "apache"
end

user node['zabbix']['web']['user']

php_packages=[]
case node['platform_family']
when "debian"
  php_packages.push( 'php5-gd');
  case node['zabbix']['database']['install_method']
  when "mysql"
    php_packages.push( 'php5-mysql');
  when "postgres"
    php_packages.push( 'php5-pgsql');
  end
when "rhel"
  if node['platform_version'].to_f < 6.0
    php_packages.push( 'php53-gd', 'php53-bcmath', 'php53-mbstring');
    case node['zabbix']['database']['install_method']
    when "mysql"
      php_packages.push( 'php53-mysql');
    when "postgres"
      php_packages.push( 'php53-pgsql');
    end
  else
    php_packages.push( 'php', 'php-gd', 'php-bcmath', 'php-mbstring', 'php-xml');
    case node['zabbix']['database']['install_method']
    when "mysql"
      php_packages.push( 'php-mysql');
    when "postgres"
      php_packages.push( 'php-pgsql');
    end
  end
when "freebsd"
  # WTF?  php5-pgsql is compiled against postgresql9.0?
  # For now, install php5-pgsql when the chef run fails to install it
  php_packages.push( 'php5-gd');
  case node['zabbix']['database']['install_method']
  when "mysql"
    php_packages.push( 'php5-mysql');
  when "postgres"
    php_packages.push( 'php5-pgsql');
  end
end

php_packages.each do |pck|
  package pck do
    action :install
    notifies :restart, "service[apache2]"
  end
end

package 'zabbix24-frontend'
#zabbix_source "extract_zabbix_web" do
#  branch              node['zabbix']['server']['branch']
#  version             node['zabbix']['server']['version']
#  source_url          node['zabbix']['server']['source_url']
#  code_dir            node['zabbix']['src_dir']
#  target_dir          "zabbix-#{node['zabbix']['server']['version']}"  
#  install_dir         node['zabbix']['install_dir']
#
#  action :extract_only
#
#end

#link node['zabbix']['web_dir'] do
#  to "#{node['zabbix']['src_dir']}/zabbix-#{node['zabbix']['server']['version']}/frontends/php"
#end

directory "#{node['zabbix']['web_dir']}/conf" do
  owner node['apache']['user']
  group node['apache']['group']
  mode "0755"
  action :create
end

# install zabbix PHP config file
template "#{node['zabbix']['web_dir']}/conf/zabbix.conf.php" do
  source "zabbix_web.conf.php.erb"
  owner "root"
  group node['root_group']
  mode "754"
  variables({
    :database => node['zabbix']['database'],
    :server => node['zabbix']['server']
  })
end

# install vhost for zabbix frontend
web_app node['zabbix']['web']['fqdn'] do
  server_name node['zabbix']['web']['fqdn']
  server_aliases node['zabbix']['web']['aliases']
  docroot node['zabbix']['web_dir']
  only_if { node['zabbix']['web']['fqdn'] != nil }
  php_settings node['zabbix']['web']['php']['settings']
  notifies :restart, "service[apache2]", :immediately 
end  

include_recipe 'apache2::mod_php5'

apache_site "000-default" do
  enable false
end
