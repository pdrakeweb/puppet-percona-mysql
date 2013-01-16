class mysqllib {

  include mysql::client

  define mysqldb( $user, $password, $clienthost = 'localhost', $host = 'localhost' ) {
    exec { "create-${name}-db-${clienthost}":
      unless => "/usr/bin/mysql -h${host} -uroot -e \"SHOW GRANTS FOR '${user}'@'${clienthost}';\" | grep 'ON `${name}`.*'",
      command => "/usr/bin/mysql -h${host} -uroot -e \"CREATE DATABASE IF NOT EXISTS ${name}; GRANT ALL ON ${name}.* TO '${user}'@'${clienthost}' IDENTIFIED BY '${password}'; FLUSH PRIVILEGES;\"",
      require => Service["mysql"],
    }
  }

}
