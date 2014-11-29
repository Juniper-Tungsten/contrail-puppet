#
# This class implements some reasonable admin defaults for keystone.
#
# It creates the following keystone objects:
#   * service tenant (tenant used by all service users)
#   * "admin" tenant (defaults to "openstack")
#   * admin user (that defaults to the "admin" tenant)
#   * admin role
#   * adds admin role to admin user on the "admin" tenant
#
# [*Parameters*]
#
# [email] The email address for the admin. Required.
# [password] The admin password. Required.
# [admin_tenant] The name of the tenant to be used for admin privileges. Optional. Defaults to openstack.
# [admin] Admin user. Optional. Defaults to admin.
# [ignore_default_tenant] Ignore setting the default tenant value when the user is created. Optional. Defaults to false.
# [admin_tenant_desc] Optional. Description for admin tenant, defaults to 'admin tenant'
# [service_tenant_desc] Optional. Description for admin tenant, defaults to 'Tenant for the openstack services'
#
# == Dependencies
# == Examples
# == Authors
#
#   Dan Bode dan@puppetlabs.com
#
# == Copyright
#
# Copyright 2012 Puppetlabs Inc, unless otherwise noted.
#
class keystone::roles::admin(
  $email,
  $password,
  $admin                  = 'admin',
  $admin_tenant           = 'openstack',
  $service_tenant         = 'services',
  $ignore_default_tenant  = false,
  $admin_tenant_desc      = 'admin tenant',
  $service_tenant_desc    = 'Tenant for the openstack services',
) {

  keystone_tenant { $service_tenant:
    ensure      => present,
    enabled     => true,
    description => $service_tenant_desc,
  }
  keystone_tenant { $admin_tenant:
    ensure      => present,
    enabled     => true,
    description => $admin_tenant_desc,
  }
  keystone_user { $admin:
    ensure                => present,
    enabled               => true,
    tenant                => $admin_tenant,
    email                 => $email,
    password              => $password,
    ignore_default_tenant => $ignore_default_tenant,
  }
  keystone_role { 'admin':
    ensure => present,
  }
  keystone_user_role { "${admin}@${admin_tenant}":
    ensure => present,
    roles  => 'admin',
  }

}
