class mysql::server {

  include mysql
  include mysql::backup
  include mysql::client

  import "./lib.pp"

  package {
    "percona-server-server-5.5":
      ensure  => installed,
      require => [ Apt::Source["percona"], Package["mysql-server"], Package["mysql-client"], Package["percona-server-common-5.5"] ],
      notify  => [ Exec["mysql-upgrade-backup"], Exec["mysql-upgrade"], Service["mysql"] ];
    "mytop": ensure => latest;
    "percona-toolkit": ensure => latest;
    "mysqltuner": ensure => latest;
  }

  if !defined(Package["mysql-server"]) {
    package { 
      "mysql-server":
        ensure  => absent,
        require => Package["mysql-server-core-5.5"];
      "mysql-server-core-5.5":
        ensure  => absent; 
    }
  }

  file { "/usr/local/bin/mysql-check-file-sizes":
    owner   => root,
    group   => root,
    mode    => 755,
    content => template('mysql/mysql-check-file-sizes.erb'),
  }

  case $environment {
    "development","importdev","integration": {
      $mysql_check_command = "mysql-check-file-sizes /var/lib/mysql repair"
    }
    default: {
      $mysql_check_command = "mysql-check-file-sizes /var/lib/mysql"
    }
  }

  exec { "mysql-check-file-sizes":
    command     => "${mysql_check_command}",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    before      => Service["mysql"],
    require     => [ Package["percona-server-server-5.5"], File["/usr/local/bin/mysql-check-file-sizes"] ],
    refreshonly => true,
  }

  exec { "mysql-upgrade":
    command     => "mysql_upgrade --force",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    notify      => Service["mysql"],
    refreshonly => true,
  }

  exec { "mysql-upgrade-backup":
    # This command is required because mysqlbackup.sh will exit with status 1 as
    # it is unable to backup the performance_schema database.
    command     => "mysqlbackup.sh || /bin/true",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    before      => Exec["mysql-upgrade"],
    require     => [ Exec["mysql-upgrade-backup-service"], File["/usr/local/bin/mysqlbackup.sh"], File["/usr/local/bin/mysql-check-file-sizes"] ],
    refreshonly => true,
  }

  exec { "mysql-upgrade-backup-service":
    command     => "service mysql status || service mysql start",
    path        => "/usr/bin:/usr/sbin:/bin:/usr/local/bin:/sbin",
    refreshonly => true,
  }

  service {"mysql":
    enable  => true,
    ensure  => running,
    require => Package["percona-server-server-5.5"],
  } # service

  file { "/usr/local/bin/slave-start":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/mysql/slave-start",
  }

  file { "/usr/local/bin/slave-stop":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/mysql/slave-stop",
  }

  file { "/usr/local/bin/tuning-primer.sh":
    owner   => root,
    group   => root,
    mode    => 755,
    source  => "puppet:///modules/mysql/tuning-primer.sh",
  }

}

class mysql::server::master {
  $bin_log                        = hiera('mysql_bin_log')
  $auto_increment_increment       = hiera('mysql_auto_increment_increment')
  $auto_increment_offset          = hiera('mysql_auto_increment_offset')
  $innodb_buffer_pool_size        = hiera('mysql_innodb_buffer_pool_size')
  $max_connections                = hiera('mysql_max_connections')
  $max_heap_table_size            = hiera('mysql_max_heap_table_size')
  $tmp_table_size                 = hiera('mysql_tmp_table_size')
  $slow_query_log                 = hiera('mysql_slow_query_log')
  $query_cache_size               = hiera('mysql_query_cache_size')
  $query_cache_limit              = hiera('mysql_query_cache_limit')
  $query_cache_type               = hiera('mysql_query_cache_type')
  $innodb_log_file_size           = hiera('mysql_innodb_log_file_size')
  $innodb_log_files_in_group      = hiera('mysql_innodb_log_files_in_group')
  $innodb_flush_log_at_trx_commit = hiera('mysql_innodb_flush_log_at_trx_commit')

  file { "/etc/mysql/my.cnf":
    owner   => root,
    group   => root,
    mode    => 644,
    content => template('mysql/my-master.cnf.erb'),
    notify  => [ Service["mysql"], Exec["mysql-check-file-sizes"] ],
  }

}

class mysql::server::slave {
  $bin_log                        = hiera('mysql_bin_log')
  $auto_increment_increment       = hiera('mysql_auto_increment_increment')
  $auto_increment_offset          = hiera('mysql_auto_increment_offset')
  $innodb_buffer_pool_size        = hiera('mysql_innodb_buffer_pool_size')
  $max_connections                = hiera('mysql_max_connections')
  $max_heap_table_size            = hiera('mysql_max_heap_table_size')
  $tmp_table_size                 = hiera('mysql_tmp_table_size')
  $query_cache_size               = hiera('mysql_query_cache_size')
  $query_cache_limit              = hiera('mysql_query_cache_limit')
  $query_cache_type               = hiera('mysql_query_cache_type')
  $server_id                      = hiera('mysql_server_id')
  $master_host                    = hiera('mysql_master_host')
  $master_user                    = hiera('mysql_master_user')
  $master_password                = hiera('mysql_master_password')
  $mysql_replicate_databases      = hiera('mysql_replicate_databases')
  $mysql_wildcard_ignore          = hiera('mysql_wildcard_ignore')
  $innodb_log_file_size           = hiera('mysql_innodb_log_file_size')
  $innodb_log_files_in_group      = hiera('mysql_innodb_log_files_in_group')
  $innodb_flush_log_at_trx_commit = hiera('mysql_innodb_flush_log_at_trx_commit')

  file { "/etc/mysql/my.cnf":
    owner   => root,
    group   => root,
    mode    => 644,
    content => template('mysql/my-slave.cnf.erb'),
    notify  => [ Service["mysql"], Exec["mysql-check-file-sizes"] ],
  }

}
