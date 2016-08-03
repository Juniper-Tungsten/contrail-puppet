class contrail::profile::openstack::neutron(
  $host_control_ip   = $::contrail::params::host_ip,
  $allowed_hosts     = $::contrail::params::os_mysql_allowed_hosts,
  $service_password  = $::contrail::params::os_mysql_service_password,
  $keystone_ip_to_use = $::contrail::params::keystone_ip_to_use,
) {

  $database_credentials = join([$service_password, "@", $host_control_ip],'')
  $keystone_db_conn = join(["mysql://neutron:",$database_credentials,"/neutron"],'')

  if ($::operatingsystem == 'Ubuntu') {
      package { 'neutron-common':
        ensure => present 
      }
  }
  if ($::operatingsystem == 'Centos' or $::operatingsystem == 'Fedora') {
     package { 'neutron-common':
       name => 'openstack-neutron',
       ensure => present
     }
  }
  class {'::neutron::db::mysql':
    password      => $service_password,
    allowed_hosts => $allowed_hosts,
  } ->

  Package ['neutron-common'] ->

  class {'::contrail::profile::neutron_db_sync':
    database_connection => $keystone_db_conn
 }
}
