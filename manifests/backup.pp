class mysql::backup ($backup_major_version = '2.5', $backup_version = '2.5.1-01') {

  $bin_log      = hiera('mysql_bin_log', 'true')
  $master_host  = hiera('mysql_master_host', 'false')
  $backup_email = hiera('mysql_backup_email', 'root@localhost')
  $backup_dbs = hiera('mysql_backup_dbs', 'all')
  $backup_user  = hiera('mysql_backup_user', 'root')
  $backup_pass  = hiera('mysql_backup_pass', '')

  file { "/mnt/mysqlbackups":
    ensure => directory,
    owner => root,
    group => admin,
    mode => 755,
  }

  file { "/etc/automysqlbackup":
    ensure => directory,
    owner => root,
    group => root,
    mode => 755,
  }

  file { "/etc/automysqlbackup/automysqlbackup.conf":
    owner   => root,
    group   => root,
    mode    => 644,
    content => template("mysql/automysqlbackup.conf.erb"),
  }

  exec { "/etc/automysqlbackup/automysqlbackup-${backup_version}.sh":
    path    => "/bin:/usr/bin:/usr/local/bin",
    cwd     => "/etc/automysqlbackup",
    command => "wget -q http://sourceforge.net/projects/automysqlbackup/files/AutoMySQLBackup/AutoMySQLBackup%20VER%20${backup_major_version}/automysqlbackup-${backup_version}.sh/download -O automysqlbackup-${backup_version}.sh",
    creates => "/etc/automysqlbackup/automysqlbackup-${backup_version}.sh",
    require => File["/etc/automysqlbackup"],
  }

  file { "/etc/automysqlbackup/automysqlbackup-${backup_version}.sh":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => 755,
    require => Exec["/etc/automysqlbackup/automysqlbackup-${backup_version}.sh"],
  }

  file { "/usr/local/bin/mysqlbackup.sh":
    ensure  => link,
    target  => "/etc/automysqlbackup/automysqlbackup-${backup_version}.sh",
    require => File["/etc/automysqlbackup/automysqlbackup-${backup_version}.sh"],
  }

}

class mysql::backup::daily {

  cron { "mysqlbackup-daily":
    ensure   => present,
    command  => "/usr/local/bin/mysqlbackup.sh > /dev/null 2>&1",
    user     => "root",
    hour     => 3,
    minute   => 0,
    require  => File["/usr/local/bin/mysqlbackup.sh"],
  }

}